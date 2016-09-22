require 'thor/scmversion'

class Test < Thor
  desc 'full', 'Run Full Test Suite'
  def full
    puts 'Full test suite'
  end

  desc 'rubocop', 'Run Rubocop test'
  def rubocop
    puts 'Rubocop'
  end

  desc 'chefspec', 'Run ChefSpec test'
  def chefspec
    puts 'chefspec'
  end

  desc 'serverspec', 'Run ServerSpec test'
  def serverspec
    puts 'serverspec'
  end

  desc 'foodcritic', 'Run FoodCritic test'
  def foodcritic
    puts 'foodcritic'
  end

  # Ref: https://github.com/seanfisk/personal-chef-repo/blob/master/Thorfile
  # TODO: Berks install and upload
end

class BerksUtil < Thor

  desc 'prep', 'Prep repo for packaging'
  option :force
  def prep
    if force

    else
      puts `git fetch origin`
      puts `git checkout master`
      puts `git reset --hard origin/master`
      puts `git clean -fd`
      puts `git checkout .`
    end
  end

  desc 'package', 'Packaging repo'
  def package
    puts `bundle install --path vendor`
    ### TODO: Investigate invoking here
    puts `bundle exec thor version:bump patch`
    exit(1) unless $?.to_i == 0
    puts `rm -rf Berksfile.lock`
    puts `berks install`
    exit(1) unless $?.to_i == 0
  end

  desc 'upload', 'Berks Upload'
  def upload
    require 'json'
    require 'httparty'
    berks_json = `berks upload -F json`
    puts berks_json
    webhook = "https://hooks.slack.com/services/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"
    data = JSON.parse(berks_json)
    send = {
      "username" => "berksBot",
      "channel" => "#general",
      "icon_emoji" => ":robot_face:"
    }
    whoami = ENV['CHEF_USER']
    message = "Following has been updated by #{whoami.strip}:\n"
    data['cookbooks'].each do |key|
     if key.has_key?('uploaded_to')
        message = message + "uploaded #{key['name']} version #{key['version']}\n"
      else
        print "Skipped #{key['name']}\n"
      end
    end
    puts message.to_s
    send['text'] = message.to_s
    HTTParty.post webhook, body: send.to_json, headers: {'content-type' => 'application/json'}
  end

  desc 'apply', 'Apply version to staging'
  def apply
    puts `git-crypt unlock`
    exit(1) unless $?.to_i == 0
    puts `knife environment from file ./secrets/staging/aws-helicarrier-staging.json`
    exit(1) unless $?.to_i == 0
    puts `berks apply aws-helicarrier-staging`
    exit(1) unless $?.to_i == 0
    puts `knife environment show aws-helicarrier-staging -F json > ./secrets/staging/aws-helicarrier-staging.json`
    exit(1) unless $?.to_i == 0
    puts `git status`
  end

end
