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
	end
end
