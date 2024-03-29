namespace :db do
  desc "Resets the database and loads it from db/dev_seeds.rb"
  task dev_seed: :environment do
    load(Rails.root.join("db", "dev_seeds.rb"))
  end
  task m_seed: :environment do
    load(Rails.root.join("db", "m_seeds.rb"))
  end
  task m_update: :environment do
    load(Rails.root.join("db", "m_update.rb"))
  end
  task reset_pw: :environment do
    load(Rails.root.join("db", "reset_pw.rb"))
  end
end
