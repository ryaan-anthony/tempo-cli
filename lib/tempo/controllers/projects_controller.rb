module Tempo
  module Controllers
    class Projects < Tempo::Controllers::Base
      @projects = Model::Project

      class << self

        def load
          if File.exists?( File.join( ENV['HOME'], 'tempo', @projects.file ))
            @projects.read_from_file
          end
        end

        def index options, args
          request = reassemble_the args

          if args.empty?
            Views::projects_list_view options

          else
            matches = filter_projects_by_title options, args

            if matches.empty?
              Views::no_match "projects", request

            else
              Views::projects_list_view({ projects: matches })
            end
          end
        end

        def add options, args, tags=nil
          request = reassemble_the args

          if @projects.include? request
            Views::already_exists "project", request

          else
            project = @projects.new({ title: request, tags: tags })

            if @projects.index.length == 1
              @projects.current = project
            end

            @projects.save_to_file

            options[:active] = false
            Views::added_item "project", Views::project_view( project, options )
          end
        end

        def delete options, args

          if options[:id]
            match = @projects.find_by_id options[:delete]
            Views::no_items "projects", options[:id] if not match
          else
            # first arg without quotes from GLI will be the value of delete
            request = reassemble_the args, options[:delete]
            matches = filter_projects_by_title options, args

            match = single_match matches, request, :delete
          end
          if match == @projects.current
            raise "cannot delete the active project"
          end

          if @projects.index.include?(match)
            match.delete
            @projects.save_to_file
            if !options[:list]
              Views::deleted_item "project", match.title
            else
              Views::projects_list_view
            end
          end
        end

        def tag options, args

          # TODO @projects_find_by_tag if args.empty?

          tags = options[:tag].split if options[:tag]
          untags = options[:untag].split if options[:untag]

          if options[:add]
            add options, args, tags
            Views::tag_view tags

          else
            if options[:id]
              match = @projects.find_by_id args[0]
              Views::no_items "projects", options[:id] if not match
            else
              request = reassemble_the args
              matches = filter_projects_by_title options, args

              command = options[:tag] ? "tag" : "untag"
              match = single_match matches, request, command
            end

            match.tag tags
            match.untag untags
            @projects.save_to_file
            puts Views::project_view match, options
          end
        end

        def active_only options
          if @projects.index.empty?
            Views::no_items( :projects )
          else
            puts Views::project_view @projects.current, options
          end
        end
      end #class << self
    end
  end
end
