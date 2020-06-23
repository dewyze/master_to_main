require "thor"
require "pry"
require "octokit"

module MasterToMain
  class CLI < Thor
    include Thor::Actions

    def self.exit_on_failure?
      true
    end

    desc "update", "rebase PRs to the main branch"
    def update
      prompt_info
      create_client

      ensure_old_branch_exists
      ensure_new_branch_exists
      clone_branch_protections
      change_default_branch
      rebase_pull_requests
      change_origin
      delete_local_old_branch
      ask_update_docs
      ask_find_references
    end

    desc "update_docs", "update local docs to use MAIN"
    def update_docs
      prompt_info
      _update_docs
      ask_find_references
    end

    desc "find_references", "find references to github urls with MAIN"
    def find_references
      prompt_info
      _find_references
    end

    desc "update_local", "point local clone to new branch"
    def update_local
      prompt_info

      `git checkout #{@repo.old_branch}`
      `git branch -m #{@repo.old_branch} #{@repo.new_branch}`
      `git fetch`
      `git branch --unset-upstream`
      `git branch -u origin/#{@repo.new_branch}`
      `git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/#{@repo.new_branch}`
      `git pull`
    end

    no_commands do
      def create_client
        if @repo.github != "github.com"
          Octokit.configure do |c|
            c.api_endpoint = @repo.api_endpoint
          end
        end
        token = ask("What is your GitHub Personal Access Token?")

        @client = Octokit::Client.new(access_token: token)
      end


      def get_github_info
        fetch_url = `git remote show origin | grep "Fetch URL"`
        if fetch_url != ""
          base = fetch_url.split("github.")[1]
          github_suffix, user_repo = base.split(":")
          user, repo = user_repo.split("/")

          {
            github: "github." + github_suffix,
            user: user,
            repo: repo.gsub(/\.git/, "").chomp,
          }
        else
          {
            github: "github.com",
            user: `whoami`.chomp,
            repo: `pwd`.split("/")[-1].chomp,
          }
        end
      end

      def prompt_info
        github_info = get_github_info
        github_url = ask("What is your github url?", default: github_info[:github]).gsub(/https:\/\//, "")
        user = ask("What is your github user?", default: github_info[:user])
        github_repo = ask("What is your github repo?", default: github_info[:repo]).gsub(/\.git/, "")
        old_branch = ask("What is your current primary branch?", default: "master")
        new_branch = ask("What is your desired primary branch?", default: "main")

        @repo = MasterToMain::Repo.new(github_url, user, github_repo, old_branch, new_branch)
      end

      def ensure_old_branch_exists
        @client.branch(@repo.name, @repo.old_branch)
      rescue Octokit::NotFound
        say "The current primary branch does not exist, or do you not have access. Was there a typo?", :red
        say "-----------------------"
        say "CURRENT PRIMARY BRANCH: #{@repo.old_branch}", :green
        exit 1
      end

      def ensure_new_branch_exists
        unless new_branch_exists?
          if yes?("The #{@repo.new_branch} branch does not exist, would you like me to create it for you?")
            create_new_branch
            say "The #{@repo.new_branch} has been created. You can see it at: #{@repo.new_branch_url}", :green
          else
            say "Okay then, goodbye."
            exit 1
          end
        end
      end

      def new_branch_exists?
        @client.branch(@repo.name, @repo.new_branch)
      rescue Octokit::NotFound
        false
      end

      def old_branch_sha
        old_branch = @client.branch(@repo.name, @repo.old_branch)[:commit][:sha]
      end

      def create_new_branch
        @client.create_ref(@repo.name, "refs/heads/#{@repo.new_branch}", old_branch_sha)
      end

      def clone_branch_protections
        begin
          repo = @client.repo(@repo.name)
          options = @client.branch_protection(@repo.name, @repo.old_branch)
        rescue Octokit::Forbidden
          return
        end

        if options && yes?("Would you like to clone branch protections from '#{@repo.old_branch}'?")
          updates =  BranchProtectionParams.build(options.to_h)
          @client.protect_branch(@repo.name, @repo.new_branch, updates)
          say "NOTE: Cannot clone Signed Commit Requirement, please recreate if necessary", :green
        end
      end

      def rebase_pull_requests
        if yes?("Would you like to rebase all pull requests based on #{@repo.old_branch} to #{@repo.new_branch}?")
          prs = @client.pull_requests(@repo.name)
          prs.each do |pr|
            if pr[:base][:ref] == @repo.old_branch
              @client.update_pull_request(@repo.name, pr.number, base: @repo.new_branch)
            end
          end
        else
          say "Be sure to update pull requests to point to the new branch!"
        end
      end

      def change_default_branch
        @client.update_repository(@repo.name, default_branch: @repo.new_branch)
      end

      def change_origin
        if yes?("Would you like to change origin to point to #{@repo.new_branch}?")
          `git fetch`
          `git checkout #{@repo.new_branch}`
          `git push -u origin #{@repo.new_branch}`
        else
          say "Be sure to change your local `origin` setting"
        end
      end

      def delete_local_old_branch
        `git branch -D #{@repo.old_branch}` if yes?("Would you like to delete your local #{@repo.old_branch} branch?")

        say "----------------"
        say "In order to ensure no builds or deployments break, please delete your remote #{@repo.old_branch} on github", :green
        say "----------------"
      end

      def ask_update_docs
        say("We can update #{@repo.github} references in '.md' files that include master in your repo")
        say("For example: https://#{@repo.github}/#{@repo.name}/(tree|blob)/master")
        if yes?("Would you like to update these references?")
          _update_docs
          say("You should consider searching for other references not in markdown files.")
          say("We don't want to automatically change those in case something breaks.")
          say("But you can use `master_to_main find_references` to show you where they are")
        end
      end

      def ask_find_references
        _find_references if yes?("Would you like to display other URL references?")
      end

      def _update_docs
        say "This will update all references of #{@repo.old_branch} to #{@repo.new_branch} in the following lines in this repo:"
        say "https://#{@repo.github}/#{@repo.name}/<tree|blob>/#{@repo.old_branch}"
        Dir.glob(File.expand_path("**/*.md", Dir.pwd)).each do |path|
          gsub_file path, /#{@repo.old_branch_regex}/, @repo.new_branch_replacement, verbose: false
        end
      end

      def _find_references
        say "Here are the references to urls with #{@repo.old_branch}:\n\n"
        puts `git grep -E '#{@repo.old_branch_regex}'`
      end
    end
  end
end
