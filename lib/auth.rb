module Symbiosis
	module SPanel
		class Auth
			def self.authenticate(username, password)
				ret = nil
				if /@/ =~ username
					user = Symbiosis::Domains.find_mailbox(username)
					if user && user.admin? && user.login(password)
						ret = [user.local_part, user.domain.name]
					end
				else
					ret = [username,"PAM"] if authpam(username, password)
				end
				ret
			end
		end
	end
end
