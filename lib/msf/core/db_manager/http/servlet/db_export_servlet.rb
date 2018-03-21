module DbExportServlet

  def self.api_path
    '/api/v1/db_export'
  end

  def self.registered(app)
    app.get DbExportServlet.api_path, &get_db_export
  end

  #######
  private
  #######

  def self.get_db_export
    lambda {
      begin
        opts = params.symbolize_keys
	      file_name = File.basename(opts[:path])

        output_file = get_db.run_db_export(File.join(Msf::Config.local_directory, file_name), opts[:format])

        encoded_file = Base64.urlsafe_encode64(File.read(File.expand_path(output_file)))
        response = {}
        response[:db_export_file] = encoded_file
        set_json_response(response)
      rescue Exception => e
        set_error_on_response(e)
      end
    }
  end
end
