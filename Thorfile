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
      `git fetch origin`
      `git checkout master`
      `git reset --hard origin/master`
      `git clean -fd`
      `git checkout .`
    end
  end

  desc 'package', 'Packaging repo'
  def package
    `bundle install --path vendor`
    ### TODO: Investigate invoking here
    `bundle exec thor version:bump patch`
    `rm -rf Berksfile.lock`
    `berks install`
  end

  desc 'upload', 'Berks Upload'
  def upload
    require 'json'
    require 'httparty'
    berks_json = `berks upload -F json`
    webhook = "https://hooks.slack.com/services/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"
    data = JSON.parse(berks_json)
    send = {
      "username" => "berksBot",
      "channel" => "#general",
      "icon_emoji" => ":robot_face:"
    }
    message = ''
    data['cookbooks'].each do |key|
     if key.has_key?('uploaded_to')
        message = message + "uploaded #{key['name']} version #{key['version']}\n"
      else
        print "Skipped #{key['name']}\n"
      end
    end
    send['text'] = message.to_s
    HTTParty.post webhook, body: send.to_json, headers: {'content-type' => 'application/json'} 
  end


end
