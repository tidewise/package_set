module Rock
    def self.install_git_hook(pkg, source_file, target_hook)
        if !File.directory?(pkg.srcdir)
            raise ArgumentError, "cannot install the git hooks for a non-checked out package"
        end

        hook_source_path = File.join(
            File.expand_path(File.dirname(__FILE__)),
            source_file)
        hook_dest_path = File.join(pkg.srcdir, '.git', 'hooks', target_hook)
        FileUtils.mkdir_p File.dirname(hook_dest_path)
        FileUtils.cp hook_source_path, hook_dest_path
    end
    def self.remove_git_hook(pkg, target_hook)
        if !File.directory?(pkg.srcdir)
            raise ArgumentError, "cannot remove the git hooks for a non-checked out package"
        end
        hook_dest_path = File.join(pkg.srcdir, '.git', 'hooks', target_hook)
        FileUtils.rm_f hook_dest_path
    end
end
