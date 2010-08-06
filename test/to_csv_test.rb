# encoding: UTF-8

require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'activerecord_test_case'))
require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'load_fixtures'))

class ToCsvTest < ActiveRecordTestCase
  fixtures :movies

  def setup
    ToCSV.byte_order_marker = ToCSV.locale = ToCSV.primary_key = ToCSV.timestamps = false
    ToCSV.csv_options = { :col_sep => ';', :encoding => 'UTF-8' }
    @movies = Movie.all
    @people = Person.all(:order => :name)
    @block_busters = BlockBuster.all
    store_translations('en-US', 'pt-BR')
  end

  def test_simple_array
    csv = ['Alfréd Hitchcock', 'Robert Mitchum', 'Lucille Ball'].to_csv
    assert_equal "Alfréd Hitchcock;Robert Mitchum;Lucille Ball\n", csv
  end

  def test_matrix
    csv = [
      ['Name', 'Age'],
      ['Icaro', 22],
      ['Gabriel', 16]
    ].to_csv

    assert_equal "Name;Age\nIcaro;22\nGabriel;16\n", csv
  end

  def test_array_of_matrixes
    csv = [
      [
        ['Name', 'Alfred'],
        ['Gender', 'M']
      ],
      [
        ['Name', 'Robert'],
        ['Gender', 'M']
      ],
      [
        ['Name', 'Lucille'],
        ['Gender', 'F']
      ]
    ].to_csv

    assert_equal "Name;Gender\nAlfred;M\nRobert;M\nLucille;F\n", csv
  end

  def test_array_of_hashes
    csv = [
      {
        'Name'   => 'Icaro',
        'E-mail' => 'icaro.ldm@gmail.com'
      },
      {
        'Name'   => 'Gabriel',
        'E-mail' => 'gaby@gmail.com'
      }
    ].to_csv

    order_01 = "Name;E-mail\nIcaro;icaro.ldm@gmail.com\nGabriel;gaby@gmail.com\n"
    order_02 = "E-mail;Name\nicaro.ldm@gmail.com;Icaro\ngaby@gmail.com;Gabriel\n"

    assert order_01 == csv || order_02 == csv
  end

  def test_without_options
    assert_equal "Cod;Dvd release date;Number of discs;Studio;Subtitles;Title\n1;2008-12-08 22:00:00;2;Warner Home Video;English, French, Spanish;The Dark Knight\n2;2007-10-22 21:00:00;1;Warner Home Video;English, Spanish, French;2001 - A Space Odyssey\n", @movies.to_csv
  end

  def test_only_option
    assert_equal "Title\nThe Dark Knight\n2001 - A Space Odyssey\n", @movies.to_csv(:only => :title)
    assert_equal @movies.to_csv(:only => :title), @movies.to_csv(:only => [:title])
    assert_equal "Studio;Title\nWarner Home Video;The Dark Knight\nWarner Home Video;2001 - A Space Odyssey\n", @movies.to_csv(:only => [:title, :studio])
  end

  def test_except_option
    assert_equal "Cod;Dvd release date;Number of discs;Subtitles;Title\n1;2008-12-08 22:00:00;2;English, French, Spanish;The Dark Knight\n2;2007-10-22 21:00:00;1;English, Spanish, French;2001 - A Space Odyssey\n", @movies.to_csv(:except => :studio)
    assert_equal @movies.to_csv(:except => :studio), @movies.to_csv(:except => [:studio])
    assert_equal "Cod;Dvd release date;Number of discs;Studio\n1;2008-12-08 22:00:00;2;Warner Home Video\n2;2007-10-22 21:00:00;1;Warner Home Video\n", @movies.to_csv(:except => [:title, :subtitles])
  end

  def test_timestamps_option
   assert_equal "Cod;Created at;Number of discs\n1;2009-12-12 00:00:00;2\n2;2009-11-11 00:00:00;1\n", @movies.to_csv(:except => [:title, :subtitles, :studio, :dvd_release_date, :updated_at])
   assert_equal "Cod;Created at;Number of discs\n1;2009-12-12 00:00:00;2\n2;2009-11-11 00:00:00;1\n", @movies.to_csv(:except => [:title, :subtitles, :studio, :dvd_release_date, :updated_at], :timestamps => false)
   assert_equal "Cod;Created at;Number of discs\n1;2009-12-12 00:00:00;2\n2;2009-11-11 00:00:00;1\n", @movies.to_csv(:except => [:title, :subtitles, :studio, :dvd_release_date, :updated_at], :timestamps => true)
  end

  def test_headers_option
    assert_equal "Icaro;23\n", ['Icaro', 23].to_csv(:headers => false)
    assert_equal "Icaro;23\n", [ [:name, :age], ['Icaro', 23] ].to_csv(:headers => false)
    assert_equal "Icaro;23\n", [ [[:name, 'Icaro'], [:age, 23]] ].to_csv(:headers => false)
    assert_equal "Subtitles;Cod;Dvd release date;Number of discs;Studio;Title\nEnglish, French, Spanish;1;2008-12-08 22:00:00;2;Warner Home Video;The Dark Knight\nEnglish, Spanish, French;2;2007-10-22 21:00:00;1;Warner Home Video;2001 - A Space Odyssey\n", @movies.to_csv(:headers => :subtitles)
    assert_equal "1;2008-12-08 22:00:00;2;Warner Home Video;English, French, Spanish;The Dark Knight\n2;2007-10-22 21:00:00;1;Warner Home Video;English, Spanish, French;2001 - A Space Odyssey\n", @movies.to_csv(:headers => false)
    assert_equal "1;2008-12-08 22:00:00;2;Warner Home Video;English, French, Spanish;The Dark Knight\n2;2007-10-22 21:00:00;1;Warner Home Video;English, Spanish, French;2001 - A Space Odyssey\n", @movies.to_csv(:headers => [false])
    assert_equal "1;2008-12-08 22:00:00;2;Warner Home Video;English, French, Spanish;The Dark Knight\n2;2007-10-22 21:00:00;1;Warner Home Video;English, Spanish, French;2001 - A Space Odyssey\n", @movies.to_csv(:headers => [])
    assert_equal "Title;Number of discs\nThe Dark Knight;2\n2001 - A Space Odyssey;1\n", @movies.to_csv(:headers => [:title, :number_of_discs], :only => [:number_of_discs, :title])
    assert_equal "Title;Number of discs\nThe Dark Knight;2\n2001 - A Space Odyssey;1\n", @movies.to_csv(:headers => [:title, :all], :only => [:number_of_discs, :title])
    assert_equal "Title;Number of discs\nThe Dark Knight;2\n2001 - A Space Odyssey;1\n", @movies.to_csv(:headers => :title, :only => [:number_of_discs, :title])
    assert_equal "Cod;Dvd release date;Number of discs;Studio;Subtitles;Title\n1;2008-12-08 22:00:00;2;Warner Home Video;English, French, Spanish;The Dark Knight\n2;2007-10-22 21:00:00;1;Warner Home Video;English, Spanish, French;2001 - A Space Odyssey\n", @movies.to_csv(:headers => :all)
    assert_equal "Cod;Dvd release date;Number of discs;Studio;Subtitles;Title\n1;2008-12-08 22:00:00;2;Warner Home Video;English, French, Spanish;The Dark Knight\n2;2007-10-22 21:00:00;1;Warner Home Video;English, Spanish, French;2001 - A Space Odyssey\n", @movies.to_csv(:headers => [:all])
    assert_equal "Cod;Dvd release date;Studio;Subtitles;Title;Number of discs\n1;2008-12-08 22:00:00;Warner Home Video;English, French, Spanish;The Dark Knight;2\n2;2007-10-22 21:00:00;Warner Home Video;English, Spanish, French;2001 - A Space Odyssey;1\n", @movies.to_csv(:headers => [:all, :subtitles, :title, :number_of_discs])
  end

  def test_locale_option
    assert_equal "Cod;Data de Lan\303\247amento do DVD;N\303\272mero de Discos;Studio;Legendas;T\303\255tulo\n1;2008-12-08 22:00:00;2;Warner Home Video;English, French, Spanish;The Dark Knight\n2;2007-10-22 21:00:00;1;Warner Home Video;English, Spanish, French;2001 - A Space Odyssey\n", @movies.to_csv(:locale => 'pt-BR')
  end

  def test_primary_key_option
    assert_equal "Block buster;Name\n1;Gabriel\n1;Icaro\n", @people.to_csv
    assert_equal "Block buster;Name\n1;Gabriel\n1;Icaro\n", @people.to_csv(:primary_key => false)
    assert_equal "Block buster;Name\n1;Gabriel\n1;Icaro\n", @people.to_csv(:primary_key => nil)
    assert_equal "Block buster;Cod;Name\n1;2;Gabriel\n1;1;Icaro\n", @people.to_csv(:primary_key => true)
    assert_equal "Number of discs\n2\n1\n", @movies.to_csv(:primary_key => true, :only => [:number_of_discs])
    assert_equal "Number of discs\n2\n1\n", @movies.to_csv(:only => [:number_of_discs, :id])
    assert_equal "Cod;Dvd release date;Number of discs;Studio;Subtitles;Title\n1;2008-12-08 22:00:00;2;Warner Home Video;English, French, Spanish;The Dark Knight\n2;2007-10-22 21:00:00;1;Warner Home Video;English, Spanish, French;2001 - A Space Odyssey\n", @movies.to_csv(:primary_key => true, :except => :id)
    assert_equal "Block buster;Name\n1;Gabriel\n1;Icaro\n", @people.to_csv(:methods => :cod)
  end

  def test_block_passed
    csv = @movies.to_csv do |row, movie|
      row.title           = movie.title.upcase
      row.number_of_discs = "%02d" % movie.number_of_discs
    end
    assert_equal "Cod;Dvd release date;Number of discs;Studio;Subtitles;Title\n1;2008-12-08 22:00:00;02;Warner Home Video;English, French, Spanish;THE DARK KNIGHT\n2;2007-10-22 21:00:00;01;Warner Home Video;English, Spanish, French;2001 - A SPACE ODYSSEY\n", csv

    csv = @movies.to_csv(:headers => [:id, :all], :primary_key => true) do |row, movie|
      row.id              = "%05d" % movie.id
      row.title           = movie.title.upcase
      row.number_of_discs = "%02d" % movie.number_of_discs
    end
    assert_equal "Id;Cod;Dvd release date;Number of discs;Studio;Subtitles;Title\n00001;1;2008-12-08 22:00:00;02;Warner Home Video;English, French, Spanish;THE DARK KNIGHT\n00002;2;2007-10-22 21:00:00;01;Warner Home Video;English, Spanish, French;2001 - A SPACE ODYSSEY\n", csv
  end

  def test_default_settings
    ToCSV.byte_order_marker = true
    ToCSV.locale            = 'pt-BR'
    ToCSV.primary_key       = true
    ToCSV.timestamps        = true
    ToCSV.csv_options       = { :col_sep => ',', :encoding => 'UTF-8' }
    assert_equal "\xEF\xBB\xBFCod,Created at,Data de Lançamento do DVD,Id,Número de Discos,Studio,Legendas,Título,Updated at\n1,2009-12-12 00:00:00,2008-12-08 22:00:00,1,2,Warner Home Video,\"English, French, Spanish\",The Dark Knight,2009-12-12 00:00:00\n", Array(@movies.first).to_csv
  end

  def test_scopes
    @movies = Movie.number_of_discs_gte(2)
    assert_equal "Title\nThe Dark Knight\n", @movies.to_csv(:only => :title)
    @movies = Movie.dvd_release_date_lte(DateTime.new(2007, 12, 31))
    assert_equal "Title\n2001 - A Space Odyssey\n", @movies.to_csv(:only => :title)
  end

  def test_include_belongs_to
    csv = @movies.to_csv(:include => :person)
    assert_equal "Cod;Dvd release date;Number of discs;Studio;Subtitles;Title;Person block buster;Person cod;Person name\n1;2008-12-08 22:00:00;2;Warner Home Video;English, French, Spanish;The Dark Knight;1;1;Icaro\n2;2007-10-22 21:00:00;1;Warner Home Video;English, Spanish, French;2001 - A Space Odyssey;1;2;Gabriel\n", csv
  end

  def test_include_has_many
    csv = @people.to_csv(:include => :movies)
    assert_equal "Block buster;Name;Movies 1 cod;Movies 1 created at;Movies 1 dvd release date;Movies 1;Movies 1 number of discs;Movies 1 studio;Movies 1 subtitles;Movies 1 title;Movies 1 updated at\n1;Gabriel;2;2009-11-11 00:00:00;2007-10-22 21:00:00;2;1;Warner Home Video;English, Spanish, French;2001 - A Space Odyssey;2009-11-11 00:00:00\n1;Icaro;1;2009-12-12 00:00:00;2008-12-08 22:00:00;1;2;Warner Home Video;English, French, Spanish;The Dark Knight;2009-12-12 00:00:00\n", csv
  end

  def test_include_has_many_and_belongs_to
    csv = @people.to_csv(:include => [:movies, :block_buster])
    assert_equal "Block buster;Name;Movies 1 cod;Movies 1 created at;Movies 1 dvd release date;Movies 1;Movies 1 number of discs;Movies 1 studio;Movies 1 subtitles;Movies 1 title;Movies 1 updated at;Block buster address\n1;Gabriel;2;2009-11-11 00:00:00;2007-10-22 21:00:00;2;1;Warner Home Video;English, Spanish, French;2001 - A Space Odyssey;2009-11-11 00:00:00;1201 Elm Street;1\n1;Icaro;1;2009-12-12 00:00:00;2008-12-08 22:00:00;1;2;Warner Home Video;English, French, Spanish;The Dark Knight;2009-12-12 00:00:00;1201 Elm Street;1\n", csv
  end

  def test_block_passed_with_include
    csv = @movies.to_csv(:include => :person) do |row, movie|
      row.title           = movie.title.upcase
      row.number_of_discs = "%02d" % movie.number_of_discs
    end
    assert_equal "Cod;Dvd release date;Number of discs;Studio;Subtitles;Title;Person block buster;Person cod;Person name\n1;2008-12-08 22:00:00;02;Warner Home Video;English, French, Spanish;THE DARK KNIGHT;1;1;Icaro\n2;2007-10-22 21:00:00;01;Warner Home Video;English, Spanish, French;2001 - A SPACE ODYSSEY;1;2;Gabriel\n", csv
  end

  private
    def store_translations(*locales)
      locale_path = File.join(File.dirname(__FILE__), 'locales')
      locales.each do |locale|
        I18n.backend.store_translations locale, YAML.load_file(File.join(locale_path, "#{ locale }.yml"))
      end
    end
end

