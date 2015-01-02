set :application, 'example.com'
set :repo_url, 'https://github.com/takuya0301/website.git'

# Branch options
# Prompts for the branch name (defaults to current branch)
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Hardcodes branch to always be master
# This could be overridden in a stage config file
#set :branch, :master

set :deploy_to, -> { "/var/www/html" }

# Use :debug for more verbose output when troubleshooting
set :log_level, :info

# Apache users with .htaccess files:
# it needs to be added to linked_files so it persists across deploys:
set :linked_files, fetch(:linked_files, []).push('.env', 'web/.htaccess')
#set :linked_files, fetch(:linked_files, []).push('.env')
set :linked_dirs, fetch(:linked_dirs, []).push('web/app/uploads')

# Theme path
set :theme_path, -> { releases_path.join(release_timestamp).join("web/app/themes/example") }

# npm
set :npm_target_path, fetch(:theme_path)
set :npm_flags, "--silent"

# Grunt
set :grunt_target_path, fetch(:theme_path)
set :grunt_tasks, 'build'
before 'deploy:updated', 'grunt'

# WP-CLI
set :wpcli_remote_url, 'http://example.com'
set :wpcli_local_url, 'http://example.dev'
set :wpcli_rsync_options, '-avz --rsh=ssh -e "ssh -i /Users/takuya/.ssh/p-wordpress.pem"'
server "example.dev", user: 'vagrant', password: 'vagrant', roles: %w{dev}
set :dev_path, '/srv/www/example.dev/current'

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :service, :nginx, :reload
    end
  end
end

# The above restart task is not run by default
# Uncomment the following line to run it on deploys if needed
# after 'deploy:publishing', 'deploy:restart'

namespace :deploy do
  desc 'Update WordPress template root paths to point to the new release'
  task :update_option_paths do
    on roles(:app) do
      within fetch(:release_path) do
        if test :wp, :core, 'is-installed'
          [:stylesheet_root, :template_root].each do |option|
            # Only change the value if it's an absolute path
            # i.e. The relative path "/themes" must remain unchanged
            # Also, the option might not be set, in which case we leave it like that
            value = capture :wp, :option, :get, option, raise_on_non_zero_exit: false
            if value != '' && value != '/themes'
              execute :wp, :option, :set, option, fetch(:release_path).join('web/wp/wp-content/themes')
            end
          end
        end
      end
    end
  end
end

# The above update_option_paths task is not run by default
# Note that you need to have WP-CLI installed on your server
# Uncomment the following line to run it on deploys if needed
# after 'deploy:publishing', 'deploy:update_option_paths'
