require 'fastlane/action'
require_relative '../helper/add_fix_version_helper'

module Fastlane
  module Actions
    class AddFixVersionAction < Action
      def self.run(params)
        
        Actions.verify_gem!('jira-ruby')
        require 'jira-ruby'
        
        site         = params[:url]
        project_id   = params[:project_key]
        version_name = params[:version_name]
        auth_type = :basic
        login = params[:login]
        password = params[:password]

        options = {
          site: site,
          auth_type: auth_type,
          username: username,
          password: password
        }

        client = JIRA::Client.new(options)

        issues = self.issue_ids_from_param(params)

        self.save_version(client, version_name, project_id, issues)
      end

      def self.issue_ids_from_param(params)
        issue_ids = params[:issue_ids]

        if issue_ids.nil?
          issue_ids = Actions.lane_context[SharedValues::FL_JIRA_ISSUE_IDS]
        end

        if issue_ids.kind_of?(Array) == false || issue_ids.empty?
          UI.user_error!("No issue ids or keys were supplied or the value is not an array.")
          return
        end

        UI.message("Issues: #{issue_ids}")
        return issue_ids
      end

      def self.save_version(client, version_name, project_key, issue_ids)
        # create new version if needed
        begin
          project = client.Project.find(project_key)
        rescue => error
          UI.error("JIRA API call failed. Check if JIRA is available and correct credentials for user with proper permissions are provided!")
          UI.user_error!(error.response)
          return
        end

        is_version_created = false
        project.versions.each do |version|
          if version.name == version_name
            is_version_created = true
            break
          end
        end

        # if the version does not exist then create this JIRA version
        if is_version_created == false
          version = project.versions.build
          create_version_parameters = { "name" => version_name, "projectId" => project.id }
          version.save(create_version_parameters)
          UI.message("#{version_name} version is created.")
        else
          UI.message("#{version_name} version already exists and will be used as a fix version.")
        end

        # update issues with fix version
        issue_ids.each do |issue_id|
          begin
            issue = client.Issue.find(issue_id)
          rescue
            UI.error("JIRA issue with #{issue_id} is not found or specified user don't have permissions to see it. It won't be updated!")
          end
          add_new_version_parameters = { 'update' => { 'fixVersions' => [{ 'add' => { 'name' => version_name } }] } }
          issue.save(add_new_version_parameters)
          UI.message("#{issue_id} is updated with fix version #{version_name}")
        end
      end

      def self.description
        "Create and mark tickets with fix version"
      end

      def self.authors
        ["Dmitry Krasulia"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Use only basic auth_type"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :url,
                               description: "A description of your option",
                                  optional: false,
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :login,
                               description: "Login for JIRA",
                                  optional: false,
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :password,
                               description: "Password for JIRA",
                                  optional: false,
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :project_key,
                               description: "JIRA project key",
                                  optional: false,
                                      type: String),

          FastlaneCore::ConfigItem.new(key: :issue_ids,
                                       description: "Issue IDs or keys for JIRA, i.e. [\"IOS-123\", \"IOS-123\"]",
                                       optional: false,
                                       is_string: false),

          FastlaneCore::ConfigItem.new(key: :version_name,
                                       description: "Version name that will be set as fix version to specified issues.\nIf version does not exist, it will be created",
                                       type: String,
                                       optional: false)

        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
