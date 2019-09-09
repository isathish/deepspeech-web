# encoding: UTF-8
require 'faktory_worker_ruby'
require 'connection_pool'
require 'securerandom'
require 'faktory'
require 'json'
require 'sqlite3'
require 'speech_to_text'

rails_environment_path = File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module MozillaDeepspeech
  class TranscriptWorker
    include Faktory::Job
    faktory_options retry: 2

    def perform(job_id)
      status = "inProgress"
      update_status(job_id, status)
      model_path = "/home/ari/workspace/temp"
      filepath = "#{Rails.root}/storage/#{job_id}"
      puts "start transcript for #{job_id}"
      SpeechToText::MozillaDeepspeechS2T.generate_transcript("#{filepath}/audio.wav", "#{filepath}/audio.json", model_path)

      if File.exist?("#{Rails.root}/storage/#{job_id}/audio.json")
        file = File.open("#{Rails.root}/storage/#{job_id}/audio.json","r")
        data = JSON.load file
        if data["words"].nil?
          status = "failed"
        else
          status = "completed"
        end
      else
        status = "failed"
      end
      update_status(job_id, status)
    end

    def update_status(job_id, status)
      db = SQLite3::Database.open "db/development.sqlite3"
      query = "update job_statuses set status = '#{status}', updated_at = '#{Time.now}' where jobID = '#{job_id}'"
      db.execute(query)
      db.close
    end

  end
end