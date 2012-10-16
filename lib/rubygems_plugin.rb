require 'rubygems'

module Gem
  class Src
    def git?(url)
      !`git ls-remote #{url} 2> /dev/null`.empty?
    end

    def git_clone(repository, directory)
      `git clone #{repository} #{directory}` if repository && !repository.empty? && git?(repository)
    end
  end
end


Gem.post_install do |installer|
  clone_dir = if ENV['GEMSRC_CLONE_ROOT']
    File.expand_path installer.spec.name, ENV['GEMSRC_CLONE_ROOT']
  elsif Gem.configuration[:gemsrc_clone_root]
    File.expand_path installer.spec.name, Gem.configuration[:gemsrc_clone_root]
  else
    gem_dir = installer.respond_to?(:gem_dir) ? installer.gem_dir : File.expand_path(File.join(installer.gem_home, 'gems', installer.spec.full_name))
    File.join gem_dir, 'src'
  end

  if (repo = installer.spec.homepage) && !repo.empty? && !File.exists?(clone_dir)
    if repo =~ /\Ahttps?:\/\/([^.]+)\.github.com\/(.+)/
      repo = if $1 == 'www'
        "https://github.com/#{$2}"
      elsif $1 == 'wiki'
        # https://wiki.github.com/foo/bar => https://github.com/foo/bar
        "https://github.com/#{$2}"
      else
        # https://foo.github.com/bar => https://github.com/foo/bar
        "https://github.com/#{$1}/#{$2}"
      end
    end

    Gem::Src.new.git_clone(repo, clone_dir)
  end
end
