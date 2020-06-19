module MasterToMain
  class Repo
    attr_accessor :github, :user, :repo_name, :old_branch, :new_branch

    def initialize(github, user, repo_name, old_branch, new_branch)
      @github = github
      @user = user
      @repo_name = repo_name
      @old_branch = old_branch
      @new_branch = new_branch
    end

    def api_endpoint
      "https://" + github + "/api/v3/"
    end

    def name
      "#{user}/#{repo_name}"
    end

    def old_branch_regex
      "(http[s]?:\/\/#{github}\/#{user}\/#{repo_name}\)/(tree|blob)\/#{old_branch}"
    end

    def new_branch_replacement
      "\\1/\\2/#{new_branch}"
    end

    def new_branch_url
      "https://#{github}/#{name}/tree/#{new_branch}"
    end

    def public_github?
      @github == "github.com"
    end
  end
end
