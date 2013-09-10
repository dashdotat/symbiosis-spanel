require 'resolv-replace'
module Symbiosis
	class Domain
		def writable?
			File.writable?(self.directory)
		end

		def is_bytemark_content_dns?
			warn "Looking up NS records for #{name}..." if $VERBOSE
			begin
				Resolv::DNS.open do |dns|
					ns = dns.getresources(name, Resolv::DNS::Resource::IN::NS)
					ns.find_all { |e| /\.ns\.bytemark\.co\.uk$/ =~ e.name.to_s }.count == ns.count
				end
			end
		end

		def mailbox_aliases
			aliases = get_param("aliases", self.config_dir)
			aliases_return = {}
			if aliases
				aliases = aliases.split("\n")
				aliases.each do |a|
					s = a.split(" ",2)
					aliases_return[s[0]] = []
					s[1].split(",").map { |v| aliases_return[s[0]] << v.gsub(" ","") }
				end
			end
			aliases_return
		end
	end
end
