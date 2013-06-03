module Symbiosis
	class Domain
		def writable?
			File.writable?(self.directory)
		end
	end
end
