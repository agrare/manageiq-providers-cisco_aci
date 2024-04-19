class ManageIQ::Providers::CiscoAci::NetworkManager < ManageIQ::Providers::NetworkManager
  supports :create
  supports :update

  def self.hostname_required?
    false
  end

  def self.params_for_create
    {
      :fields => [
        {
          :component => 'sub-form',
          :name      => 'endpoints-subform',
          :title     => _('Endpoints'),
          :fields    => [
            {
              :component              => 'validate-provider-credentials',
              :name                   => 'authentications.default.valid',
              :skipSubmit             => true,
              :validationDependencies => %w[type zone_id],
              :fields                 => [
                {
                  :component  => "text-field",
                  :name       => "endpoints.default.url",
                  :label      => _("URL"),
                  :isRequired => true,
                  :validate   => [{:type => "required"}],
                },
                {
                  :component  => "text-field",
                  :name       => "authentications.default.userid",
                  :label      => "Username",
                  :isRequired => true,
                  :validate   => [{:type => "required"}]
                },
                {
                  :component  => "password-field",
                  :name       => "authentications.default.password",
                  :label      => "Password",
                  :type       => "password",
                  :isRequired => true,
                  :validate   => [{:type => "required"}]
                },
              ]
            }
          ]
        }
      ]
    }
  end

  def self.raw_connect(url, verify_ssl: false)
    require "faraday"
    Faraday.new(:url => url, :headers => {'Content-Type' => 'application/json'}, :ssl => {:verify => verify_ssl})
  end

  def self.verify_credentials(args)
    default_endpoint = args.dig("endpoints", "default")
    url, verify_ssl = default_endpoint&.values_at("url", "verify_ssl")

    verify_ssl = verify_ssl == OpenSSL::SSL::VERIFY_PEER

    authtype = args.dig("authentications").keys.first
    authentication = args.dig("authentications", authtype)
    userid, password = authentication&.values_at("userid", "password")

    password = ManageIQ::Password.try_decrypt(password)
    password ||= find(args["id"]).authentication_password(authtype) if args["id"]

    response = raw_connect(url, :verify_ssl => verify_ssl).post("/api/aaaLogin.json") do |req|
        req.body = {
          "aaaUser" => {
            "attributes" => {
              "name" => userid,
              "pwd"  => password
          }
        }
      }.to_json
    end

    return true if response.success?

    error = begin
      JSON.parse(response.body).dig("imdata", 0, "error", "attributes", "text")
    rescue JSON::ParserError
      nil
    end

    error ||= response.reason_phrase

    raise error
  end

  def verify_credentials(auth_type = nil, options = {})
    begin
      self.class.verify_credentials(
        "endpoints"       => {"default" => {"url" => url}},
        "authentications" => {"default" => {"userid" => default_userid, "password" => default_password}}
      )
    rescue => err
      raise MiqException::MiqInvalidCredentialsError, err.message
    end

    true
  end

  def connect(options = {})
    raise MiqException::MiqHostError, "No credentials defined" if missing_credentials?(options[:auth_type])

    login_params = {
      "aaaUser" => {
        "attributes" => {
          "name" => default_userid,
          "pwd"  => default_password
        }
      }
    }

    aci = self.class.raw_connect(url)

    response = aci.post("/api/aaaLogin.json", login_params.to_json, "Content-Type" => "application/json")
    unless response.success?
      error = begin
        JSON.parse(response.body).dig("imdata", 0, "error", "attributes", "text")
      rescue JSON::ParserError
        nil
      end

      error ||= response.reason_phrase

      raise MiqException::MiqInvalidCredentialsError, error
    end

    token = JSON.parse(response.body).dig("imdata", 0, "aaaLogin", "attributes", "token")

    aci.headers["Cookie"] = "APIC-Cookie=#{token}"
    aci
  end

  def self.ems_type
    @ems_type ||= "cisco_aci".freeze
  end

  def self.description
    @description ||= "Cisco ACI".freeze
  end
end
