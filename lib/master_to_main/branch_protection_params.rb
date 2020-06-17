module MasterToMain
  class BranchProtectionParams
    def self.build(current)
      params = {}

      params[:required_status_checks] = build_required_status_checks(current)
      params[:required_pull_request_reviews] = build_required_pull_request_reviews(current)
      params[:restrictions] = build_restrictions(current)
      params[:enforce_admins] = current.dig(:enforce_admins, :enabled)
      params[:required_linear_history] = current.dig(:required_linear_history, :enabled)
      params[:allow_force_pushes] = current.dig(:allow_force_pushes, :enabled)
      params[:allow_deletions] = current.dig(:allow_deletions, :enabled)

      params
    end

    class << self
      private

      def build_required_status_checks(current)
        config = current[:required_status_checks]
        return nil unless config

        {
          strict: config[:strict],
          contexts: config[:contexts]
        }
      end

      def build_required_pull_request_reviews(current)
        config = current[:required_pull_request_reviews]
        return nil unless config

        {
          dismiss_stale_reviews: config[:dismiss_stale_reviews],
          require_code_owner_reviews: config[:require_code_owner_reviews],
          required_approving_review_count: config[:required_approving_review_count],
          dismissal_restrictions: build_dismissal_restrictions(config),
        }
      end

      def build_dismissal_restrictions(current)
        config = current[:dismissal_restrictions]
        return nil unless config

        {
          users: config[:users].map {|user| user[:login]},
          teams: config[:teams].map {|team| team[:slug]},
        }
      end

      def build_restrictions(current)
        config = current[:restrictions]
        return nil unless config

        {
          users: config[:users].map {|user| user[:login]},
          teams: config[:teams].map {|team| team[:slug]},
          apps: config[:apps].map {|app| app[:slug]},
        }
      end
    end
  end
end
