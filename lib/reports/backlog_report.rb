# Copyright 2018 Square Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

module Reports
  module BacklogReport
    def self.generate_csv(start_date, end_date)
      # verify that the params are dates
      raise ArgumentError, 'start_date is not a date' unless start_date.instance_of?(Date)
      raise ArgumentError, 'end_date is not a date' unless end_date.instance_of?(Date)

      # verify that the end date is after the start dates
      raise ArgumentError, 'end_date cannot be earlier than the start date' if end_date < start_date

      CSV.generate do |csv|
        translations  = retrieve_translations(start_date, end_date)

        languages = translations.map(&:rfc5646_locale).uniq.sort
        lang_count = languages.count
        empty_cols = Array.new(lang_count, '')

        csv << ['Start Date', start_date] + empty_cols
        csv << ['End Date', end_date] + empty_cols
        csv << ['Backlog Word Report', ''] + empty_cols
        csv << ['', ''] + empty_cols
        csv << ['Date', ''] + languages.map {|l| "#{l} (total words)"}

        start_date.upto(end_date).each do |date|
          row = [date.strftime('%Y-%m-%d'), '']

          # for each date, find the number of new words for each language
          languages.each do |language|
            words = translations.select do |t|
              t.rfc5646_locale == language &&
              date >= t.created_at &&
              (t.translation_date == nil || t.translation_date > date)
            end

            lang_total = words.sum(&:words) || 0
            row += [lang_total]
          end

          # exclude empty rows (all zeroes)
          csv << row unless (row[(lang_count * -1), lang_count]).reduce(:+) == 0
        end
      end
    end

    def self.retrieve_translations(start_date, end_date)
      translations = Translation.where('rfc5646_locale != source_rfc5646_locale')
                                .where('created_at <= ?', end_date)
                                .where('(translation_date >= ? OR translation_date is null)', start_date)
                                .where('(tm_match < 60.0 OR tm_match is null)')
                                .group('DATE(created_at), DATE(translation_date), rfc5646_locale')

      translations.select('DATE(created_at) as created_at', 'DATE(translation_date) as translation_date', :rfc5646_locale, 'SUM(words_count) as words')
    end

    private_class_method :retrieve_translations
  end
end
