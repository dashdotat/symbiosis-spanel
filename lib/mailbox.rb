module Symbiosis
	class Domain
		class Mailbox
			def admin?
				if self.exists?
					param = get_param("admin", self.directory)
				else
					param = false
				end
				param
			end

			def admin=(value)
				raise ArgumentError unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
				if self.exists?
					set_param("admin", true, self.directory)
				end
			end
		end
	end
end
