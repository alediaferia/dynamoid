# frozen_string_literal: true

require 'spec_helper'

describe 'Dumping' do
  describe 'Boolean field' do
    context 'string format' do
      let(:klass) do
        new_class do
          field :active, :boolean, store_as_native_boolean: false
        end
      end

      it "saves false as 'f'" do
        obj = klass.create(active: false)
        expect(reload(obj).active).to eql(false)
        expect(raw_attributes(obj)[:active]).to eql('f')
      end

      it "saves true as 't'" do
        obj = klass.create(active: true)
        expect(reload(obj).active).to eql(true)
        expect(raw_attributes(obj)[:active]).to eql('t')
      end

      it 'stores nil value' do
        obj = klass.create(active: nil)
        expect(reload(obj).active).to eql(nil)
        expect(raw_attributes(obj)[:active]).to eql(nil)
      end
    end

    context 'boolean format' do
      let(:klass) do
        new_class do
          field :active, :boolean, store_as_native_boolean: true
        end
      end

      it 'saves false as false' do
        obj = klass.create(active: false)
        expect(reload(obj).active).to eql(false)
        expect(raw_attributes(obj)[:active]).to eql(false)
      end

      it 'saves true as true' do
        obj = klass.create(active: true)
        expect(reload(obj).active).to eql(true)
        expect(raw_attributes(obj)[:active]).to eql(true)
      end

      it 'saves and loads boolean field correctly' do
        obj = klass.create(active: true)
        expect(reload(obj).active).to eql true

        obj = klass.create(active: false)
        expect(reload(obj).active).to eql false
      end

      it 'stores nil value' do
        obj = klass.create(active: nil)
        expect(reload(obj).active).to eql(nil)
        expect(raw_attributes(obj)[:active]).to eql(nil)
      end
    end

    describe '"store_boolean_as_native" global config option' do
      it 'is stored as boolean by default' do
        klass = new_class do
          field :active, :boolean
        end
        obj = klass.create(active: true)

        expect(raw_attributes(obj)[:active]).to eql(true)
        expect(reload(obj).active).to eql(true)
      end

      context 'store_boolean_as_native=true' do
        it 'is stored as boolean if field option store_as_native_boolean is not set',
          config: { store_boolean_as_native: true } do

          klass = new_class do
            field :active, :boolean
          end
          obj = klass.create(active: true)

          expect(raw_attributes(obj)[:active]).to eql(true)
          expect(reload(obj).active).to eql(true)
        end

        it 'is stored as boolean if field option store_as_native_boolean=true',
          config: { store_boolean_as_native: true } do

          klass = new_class do
            field :active, :boolean, store_as_native_boolean: true
          end
          obj = klass.create(active: true)

          expect(raw_attributes(obj)[:active]).to eql(true)
          expect(reload(obj).active).to eql(true)
        end

        it 'is stored as string if field option store_as_native_boolean=false',
          config: { store_boolean_as_native: true } do

          klass = new_class do
            field :active, :boolean, store_as_native_boolean: false
          end
          obj = klass.create(active: true)

          expect(raw_attributes(obj)[:active]).to eql('t')
          expect(reload(obj).active).to eql(true)
        end
      end

      context 'store_boolean_as_native=false' do
        it 'is stored as string if field option store_as_native_boolean is not set',
          config: { store_boolean_as_native: false } do

          klass = new_class do
            field :active, :boolean
          end
          obj = klass.create(active: true)

          expect(raw_attributes(obj)[:active]).to eql('t')
          expect(reload(obj).active).to eql(true)
        end

        it 'is stored as boolean if field option store_as_native_boolean=true',
          config: { store_boolean_as_native: false } do

          klass = new_class do
            field :active, :boolean, store_as_native_boolean: true
          end
          obj = klass.create(active: true)

          expect(raw_attributes(obj)[:active]).to eql(true)
          expect(reload(obj).active).to eql(true)
        end

        it 'is stored as string if field option store_as_native_boolean=false',
          config: { store_boolean_as_native: false } do

          klass = new_class do
            field :active, :boolean, store_as_native_boolean: false
          end
          obj = klass.create(active: true)

          expect(raw_attributes(obj)[:active]).to eql('t')
          expect(reload(obj).active).to eql(true)
        end
      end
    end
  end

  describe 'DateTime field' do
    context 'Stored in :number format' do
      let(:klass) do
        new_class do
          field :sent_at, :datetime
        end
      end

      it 'saves time as :number' do
        time = Time.utc(2018, 7, 24, 22, 4, 30, 1).to_datetime
        obj = klass.create(sent_at: time)
        expect(reload(obj).sent_at).to eql(time)
        expect(raw_attributes(obj)[:sent_at]).to eql(BigDecimal('1532469870.000001'))
      end

      it 'saves date as :number' do
        obj = klass.create(sent_at: Date.new(2018, 7, 21))
        expect(reload(obj).sent_at).to eq(DateTime.new(2018, 7, 21, 0, 0, 0))
        expect(raw_attributes(obj)[:sent_at]).to eql(BigDecimal('1532131200.0'))
      end

      it 'does not loose precision and can be used as sort key', :bugfix do
        klass = new_class do
          range :expired_at, :datetime
        end

        models = (1..100).map { klass.create(expired_at: Time.now) }
        loaded_models = models.map { |m| klass.find(m.id, range_key: m.expired_at) }

        expect do
          loaded_models.map { |m| klass.find(m.id, range_key: m.expired_at) }
        end.not_to raise_error
      end

      it 'stores nil value' do
        obj = klass.create(sent_at: nil)
        expect(reload(obj).sent_at).to eql(nil)
        expect(raw_attributes(obj)[:sent_at]).to eql(nil)
      end
    end

    context 'Stored in :string ISO-8601 format',
      config: { application_timezone: :utc, dynamodb_timezone: :utc } do

      let(:klass) do
        new_class do
          field :sent_at, :datetime, store_as_string: true
        end
      end

      it 'saves time as a :string and looses milliseconds' do
        time = '2018-07-24 22:04:30.001 +03:00'.to_datetime
        obj = klass.create(sent_at: time)

        expect(reload(obj).sent_at).to eql('2018-07-24 19:04:30 +00:00'.to_datetime)
        expect(raw_attributes(obj)[:sent_at]).to eql('2018-07-24T19:04:30+00:00')
      end

      it 'saves date as :string' do
        date = Date.new(2018, 7, 21)
        obj = klass.create(sent_at: date)

        expect(reload(obj).sent_at).to eq(DateTime.new(2018, 7, 21, 0, 0, 0, '+00:00'))
        expect(raw_attributes(obj)[:sent_at]).to eql('2018-07-21T00:00:00+00:00')
      end

      it 'saves as :string if global option :store_date_time_as_string is true' do
        klass2 = new_class do
          field :sent_at, :datetime
        end

        store_datetime_as_string = Dynamoid.config.store_datetime_as_string
        Dynamoid.config.store_datetime_as_string = true

        time = '2018-07-24 22:04:30.001 +03:00'.to_datetime
        obj = klass2.create(sent_at: time)

        expect(reload(obj).sent_at).to eql('2018-07-24 19:04:30 +00:00'.to_datetime)
        expect(raw_attributes(obj)[:sent_at]).to eql('2018-07-24T19:04:30+00:00')

        Dynamoid.config.store_datetime_as_string = store_datetime_as_string
      end

      it 'prioritize field option over global one' do
        store_datetime_as_string = Dynamoid.config.store_datetime_as_string
        Dynamoid.config.store_datetime_as_string = false

        time = '2018-07-24 22:04:30.001 +03:00'.to_datetime
        obj = klass.create(sent_at: time)

        expect(reload(obj).sent_at).to eql('2018-07-24 19:04:30 +00:00'.to_datetime)
        expect(raw_attributes(obj)[:sent_at]).to eql('2018-07-24T19:04:30+00:00')

        Dynamoid.config.store_datetime_as_string = store_datetime_as_string
      end

      it 'stores nil value' do
        obj = klass.create(sent_at: nil)
        expect(reload(obj).sent_at).to eq(nil)
        expect(raw_attributes(obj)[:sent_at]).to eql(nil)
      end
    end

    describe '"application_timezone" global config option' do
      let(:klass) do
        new_class do
          field :last_logged_in_at, :datetime
        end
      end

      it 'loads time in local time zone if config.application_timezone = :local',
        config: { application_timezone: :local } do
        time = DateTime.now
        obj = klass.create(last_logged_in_at: time)
        obj = klass.find(obj.id)

        # we can't compare objects directly because lose precision of milliseconds in conversions
        expect(obj.last_logged_in_at).to be_a(DateTime)
        expect(obj.last_logged_in_at.to_s).to eql time.to_datetime.to_s
      end

      it 'loads time in specified time zone if config.application_timezone = time zone name',
        config: { application_timezone: 'Hawaii' } do
        # Hawaii UTC-10
        time = '2017-06-20 08:00:00 +0300'.to_datetime
        obj = klass.create(last_logged_in_at: time)

        expect(reload(obj).last_logged_in_at).to eql '2017-06-19 19:00:00 -1000'.to_datetime
      end

      it 'loads time in UTC if config.application_timezone = :utc',
        config: { application_timezone: :utc } do
        time = '2017-06-20 08:00:00 +0300'.to_datetime
        obj = klass.create(last_logged_in_at: time)

        expect(reload(obj).last_logged_in_at).to eql '2017-06-20 05:00:00 +0000'.to_datetime
      end
    end

    describe '"dynamodb_timezone" global config option' do
      let(:klass) do
        new_class do
          field :last_logged_in_at, :datetime
        end
      end

      it 'stores time in local time zone',
        config: { dynamodb_timezone: :local, store_datetime_as_string: true } do
        time = DateTime.now
        obj = klass.create(last_logged_in_at: time)

        expect(raw_attributes(obj)[:last_logged_in_at]).to eql time.to_s
      end

      it 'stores time in specified time zone',
        config: { dynamodb_timezone: 'Hawaii', store_datetime_as_string: true } do
        time = '2017-06-20 08:00:00 +0300'.to_datetime
        obj = klass.create(last_logged_in_at: time)

        expect(raw_attributes(obj)[:last_logged_in_at]).to eql('2017-06-19T19:00:00-10:00')
      end

      it 'stores time in UTC',
        config: { dynamodb_timezone: :utc, store_datetime_as_string: true } do
        time = '2017-06-20 08:00:00 +0300'.to_datetime
        obj = klass.create(last_logged_in_at: time)

        expect(raw_attributes(obj)[:last_logged_in_at]).to eql('2017-06-20T05:00:00+00:00')
      end

      it 'uses UTC by default',
        config: { store_datetime_as_string: true } do
        time = '2017-06-20 08:00:00 +0300'.to_datetime
        obj = klass.create(last_logged_in_at: time)

        expect(raw_attributes(obj)[:last_logged_in_at]).to eql('2017-06-20T05:00:00+00:00')
      end

      it 'converts time between application time zone and dynamodb time zone correctly',
        config: { application_timezone: 'Hong Kong', dynamodb_timezone: 'Hawaii', store_datetime_as_string: true } do
        # Hong Kong +8
        # Hawaii -10
        time = '2017-06-20 08:00:00 +0300'.to_datetime
        obj = klass.create(last_logged_in_at: time)

        expect(raw_attributes(obj)[:last_logged_in_at]).to eql('2017-06-19T19:00:00-10:00')
        expect(reload(obj).last_logged_in_at.to_s).to eql('2017-06-20T13:00:00+08:00')
      end
    end
  end

  describe 'Date field' do
    context 'stored in :string format' do
      it 'stores in ISO 8601 format' do
        klass = new_class do
          field :signed_up_on, :date, store_as_string: true
        end

        obj = klass.create(signed_up_on: '2017-09-25'.to_date)
        expect(reload(obj).signed_up_on).to eql('2017-09-25'.to_date)
        expect(raw_attributes(obj)[:signed_up_on]).to eql('2017-09-25')
      end

      it 'stores in string format when global option :store_date_as_string is true' do
        klass = new_class do
          field :signed_up_on, :date
        end

        store_date_as_string = Dynamoid.config.store_date_as_string
        Dynamoid.config.store_date_as_string = true

        obj = klass.create(signed_up_on: '2017-09-25'.to_date)
        expect(raw_attributes(obj)[:signed_up_on]).to eql('2017-09-25')

        Dynamoid.config.store_date_as_string = store_date_as_string
      end

      it 'prioritize field option over global one' do
        klass = new_class do
          field :signed_up_on, :date, store_as_string: true
        end

        store_date_as_string = Dynamoid.config.store_date_as_string
        Dynamoid.config.store_date_as_string = false

        obj = klass.create(signed_up_on: '2017-09-25'.to_date)
        expect(raw_attributes(obj)[:signed_up_on]).to eql('2017-09-25')

        Dynamoid.config.store_date_as_string = store_date_as_string
      end

      it 'stores nil value' do
        klass = new_class do
          field :signed_up_on, :date, store_as_string: true
        end

        obj = klass.create(signed_up_on: nil)
        expect(reload(obj).signed_up_on).to eql(nil)
        expect(raw_attributes(obj)[:signed_up_on]).to eql(nil)
      end
    end

    context 'stored in :number format' do
      it 'stores as number of days between dates' do
        klass = new_class do
          field :signed_up_on, :date, store_as_string: false
        end

        obj = klass.create(signed_up_on: '2017-09-25'.to_date)
        expect(reload(obj).signed_up_on).to eql('2017-09-25'.to_date)
        expect(raw_attributes(obj)[:signed_up_on]).to eql(17_434)
      end

      it 'stores in number format when global option :store_date_as_string is false' do
        klass = new_class do
          field :signed_up_on, :date
        end

        store_date_as_string = Dynamoid.config.store_date_as_string
        Dynamoid.config.store_date_as_string = false

        obj = klass.create(signed_up_on: '2017-09-25'.to_date)
        expect(raw_attributes(obj)[:signed_up_on]).to eql(17_434)

        Dynamoid.config.store_date_as_string = store_date_as_string
      end

      it 'prioritize field option over global one' do
        klass = new_class do
          field :signed_up_on, :date, store_as_string: false
        end

        store_date_as_string = Dynamoid.config.store_date_as_string
        Dynamoid.config.store_date_as_string = true

        obj = klass.create(signed_up_on: '2017-09-25'.to_date)
        expect(raw_attributes(obj)[:signed_up_on]).to eql(17_434)

        Dynamoid.config.store_date_as_string = store_date_as_string
      end

      it 'stores nil value' do
        klass = new_class do
          field :signed_up_on, :date, store_as_string: false
        end

        obj = klass.create(signed_up_on: nil)
        expect(reload(obj).signed_up_on).to eql(nil)
        expect(raw_attributes(obj)[:signed_up_on]).to eql(nil)
      end
    end
  end

  describe 'Set field' do
    let(:klass) do
      new_class do
        field :string_set, :set
        field :integer_set, :set, of: :integer
        field :number_set, :set, of: :number
      end
    end

    it 'stored a string set' do
      set = Set.new(%w[a b])
      obj = klass.create(string_set: set)

      expect(reload(obj).string_set).to eql(set)
      expect(raw_attributes(obj)[:string_set]).to eql(set)
    end

    it 'stored an integer set' do
      set = Set.new([1, 2])
      obj = klass.create(integer_set: Set.new([1, 2]))
      expect(reload(obj).integer_set).to eql(Set.new([1, 2]))
      expect(raw_attributes(obj)[:integer_set]).to eql(Set.new([BigDecimal(1), BigDecimal(2)]))
    end

    it 'stored a number set' do
      obj = klass.create(number_set: Set.new([1, 2]))
      expect(reload(obj).number_set).to eql(Set.new([BigDecimal(1), BigDecimal(2)]))
      expect(raw_attributes(obj)[:number_set]).to eql(Set.new([BigDecimal(1), BigDecimal(2)]))
    end

    it 'stores empty set as nil' do
      obj = klass.create(integer_set: Set.new)
      expect(reload(obj).integer_set).to eql(nil)
      expect(raw_attributes(obj)[:integer_set]).to eql(nil)
    end

    it 'stores nil value' do
      obj = klass.create(string_set: nil)
      expect(reload(obj).string_set).to eql(nil)
      expect(raw_attributes(obj)[:string_set]).to eql(nil)
    end
  end

  describe 'Array field' do
    let(:klass) do
      new_class do
        field :tags, :array
      end
    end

    it 'stores array as list' do
      array = %w[new archived]
      obj = klass.create(tags: array)

      expect(reload(obj).tags).to eql(array)
      expect(raw_attributes(obj)[:tags]).to eql(array)
    end

    it 'can store empty array' do
      obj = klass.create(tags: [])
      expect(reload(obj).tags).to eql([])
      expect(raw_attributes(obj)[:tags]).to eql([])
    end

    it 'can store elements of different types' do
      array = ['a', 5, 12.5]
      obj = klass.create(tags: array)

      expect(reload(obj).tags).to eql(array)
      expect(raw_attributes(obj)[:tags]).to eql(array)
    end

    it 'stores document as an array element' do
      obj = klass.create(tags: [{ foo: 'bar' }])
      expect(reload(obj).tags).to eql([{ 'foo' => 'bar' }])
      expect(raw_attributes(obj)[:tags]).to eql([{ 'foo' => 'bar' }])

      array = %w[foo bar]
      obj = klass.create(tags: [array])
      expect(reload(obj).tags).to eql([array])
      expect(raw_attributes(obj)[:tags]).to eql([array])
    end

    it 'stores set as an array element' do
      set = Set.new(%w[foo bar])
      obj = klass.create(tags: [set])

      expect(reload(obj).tags).to eql([set])
      expect(raw_attributes(obj)[:tags]).to eql([set])
    end

    it 'stores nil value' do
      obj = klass.create(tags: nil)
      expect(reload(obj).tags).to eql(nil)
      expect(raw_attributes(obj)[:tags]).to eql(nil)
    end
  end

  describe 'String field' do
    it 'stores as strings' do
      klass = new_class do
        field :name, :string
      end

      obj = klass.create(name: 'Matthew')
      expect(reload(obj).name).to eql('Matthew')
      expect(raw_attributes(obj)[:name]).to eql('Matthew')
    end

    it 'saves empty string as nil' do
      klass = new_class do
        field :name, :string
      end

      obj = klass.create(name: '')
      expect(reload(obj).name).to eql(nil)
      expect(raw_attributes(obj)[:name]).to eql(nil)
    end

    it 'is used as default field type' do
      klass = new_class do
        field :name
      end

      obj = klass.create(name: 'Matthew')
      expect(reload(obj).name).to eql('Matthew')
      expect(raw_attributes(obj)[:name]).to eql('Matthew')
    end

    it 'stores nil value' do
      klass = new_class do
        field :name, :string
      end

      obj = klass.create(name: nil)
      expect(reload(obj).name).to eql(nil)
      expect(raw_attributes(obj)[:name]).to eql(nil)
    end
  end

  describe 'Raw field' do
    let(:klass) do
      new_class do
        field :config, :raw
      end
    end

    it 'stores Hash attribute as a Document' do
      config = { acres: 5, 'trees' => { cyprus: 30 }, horses: %w[Lucky Dummy] }
      obj = klass.create(config: config)

      expect(reload(obj).config).to eql(
        acres: 5, trees: { cyprus: 30 }, horses: %w[Lucky Dummy]
      )
      expect(raw_attributes(obj)[:config]).to eql(
        'acres' => 5, 'trees' => { 'cyprus' => 30 }, 'horses' => %w[Lucky Dummy]
      )
    end

    it 'stores Array attribute as a List' do
      config = %w[windows roof doors]
      obj = klass.create(config: config)

      expect(reload(obj).config).to eql(config)
      expect(raw_attributes(obj)[:config]).to eql(config)
    end

    it 'stores Set attribute as a List' do
      config = Set.new(%w[windows roof doors])
      obj = klass.create(config: config)

      expect(reload(obj).config).to eql(config)
      expect(raw_attributes(obj)[:config]).to eql(config)
    end

    it 'stores String attribute as a String' do
      config = 'Config'
      obj = klass.create(config: config)

      expect(reload(obj).config).to eql(config)
      expect(raw_attributes(obj)[:config]).to eql(config)
    end

    it 'stores Number attribute as a Number' do
      config = 100
      obj = klass.create(config: config)

      expect(reload(obj).config).to eql(config)
      expect(raw_attributes(obj)[:config]).to eql(config)
    end

    it 'stores nil value' do
      obj = klass.create(config: nil)
      expect(reload(obj).config).to eql(nil)
      expect(raw_attributes(obj)[:config]).to eql(nil)
    end

    describe 'Hash' do
      it 'symbolizes deeply Hash keys' do
        config = { 'foo' => { 'bar' => 1 }, 'baz' => [{ 'foobar' => 2 }] }
        obj = klass.create(config: config)

        expect(reload(obj).config).to eql(
          foo: { bar: 1 }, baz: [{ foobar: 2 }]
        )
      end
    end
  end

  describe 'Integer field' do
    let(:klass) do
      new_class do
        field :count, :integer
      end
    end

    it 'stores integer value as Integer' do
      obj = klass.create(count: 10)
      expect(reload(obj).count).to eql(10)
      expect(raw_attributes(obj)[:count]).to eql(10)
    end

    it 'stores nil value' do
      obj = klass.create(count: nil)
      expect(reload(obj).count).to eql(nil)
      expect(raw_attributes(obj)[:count]).to eql(nil)
    end
  end

  describe 'Number field' do
    let(:klass) do
      new_class do
        field :count, :number
      end
    end

    it 'stores integer value as Number' do
      obj = klass.create(count: 10)
      expect(reload(obj).count).to eql(BigDecimal(10))
      expect(raw_attributes(obj)[:count]).to eql(BigDecimal(10))
    end

    it 'stores float value Number' do
      obj = klass.create(count: 10.001)
      expect(reload(obj).count).to eql(BigDecimal('10.001'))
      expect(raw_attributes(obj)[:count]).to eql(BigDecimal('10.001'))
    end

    it 'stores BigDecimal value as Number' do
      obj = klass.create(count: BigDecimal('10.001'))
      expect(reload(obj).count).to eql(BigDecimal('10.001'))
      expect(raw_attributes(obj)[:count]).to eql(BigDecimal('10.001'))
    end

    it 'stores nil value' do
      obj = klass.create(count: nil)
      expect(reload(obj).count).to eql(nil)
      expect(raw_attributes(obj)[:count]).to eql(nil)
    end
  end

  describe 'Serialized field' do
    it 'uses YAML format by default' do
      klass = new_class do
        field :options, :serialized
      end

      options = { foo: 'bar' }
      obj = klass.create(options: options)

      expect(reload(obj).options).to eql(options)
      expect(raw_attributes(obj)[:options]).to eql(options.to_yaml)
    end

    it 'uses specified serializer object' do
      serializer = Class.new do
        def self.dump(value)
          JSON.dump(value)
        end

        def self.load(str)
          JSON.parse(str)
        end
      end

      klass = new_class do
        field :options, :serialized, serializer: serializer
      end

      obj = klass.create(options: { foo: 'bar' })
      expect(reload(obj).options).to eql('foo' => 'bar')
      expect(raw_attributes(obj)[:options]).to eql('{"foo":"bar"}')
    end

    it 'can store empty collections' do
      klass = new_class do
        field :options, :serialized
      end

      obj = klass.create(options: Set.new)
      expect(reload(obj).options).to eql(Set.new)
      expect(raw_attributes(obj)[:options]).to eql("--- !ruby/object:Set\nhash: {}\n")
    end

    it 'stores nil value' do
      klass = new_class do
        field :options, :serialized
      end

      obj = klass.create(options: nil)
      expect(reload(obj).options).to eql(nil)
      expect(raw_attributes(obj)[:options]).to eql(nil.to_yaml)
    end
  end

  describe 'Custom type field' do
    context 'Custom type provided' do
      let(:user_class) do
        Class.new do
          attr_accessor :name

          def initialize(name)
            self.name = name
          end

          def dynamoid_dump
            name
          end

          def eql?(other)
            name == other.name
          end

          def self.dynamoid_load(string)
            new(string.to_s)
          end
        end
      end

      let(:klass) do
        new_class(user_class: user_class) do |options|
          field :user, options[:user_class]
        end
      end

      it 'dumps and loads self' do
        user = user_class.new('John')
        obj = klass.create(user: user)

        expect(obj.user).to eql(user)
        expect(reload(obj).user).to eql(user)
        expect(raw_attributes(obj)[:user]).to eql('John')
      end
    end

    context 'Adapter provided' do
      let(:user_class) do
        Class.new do
          attr_accessor :name

          def initialize(name)
            self.name = name
          end

          def eql?(other)
            name == other.name
          end
        end
      end

      let(:adapter) do
        Class.new.tap do |c|
          c.class_exec(user_class) do |user_class|
            @user_class = user_class

            def self.dynamoid_dump(user)
              user.name
            end

            def self.dynamoid_load(string)
              @user_class.new(string.to_s)
            end
          end
        end
      end

      let(:klass) do
        new_class(adapter: adapter) do |options|
          field :user, options[:adapter]
        end
      end

      it 'dumps and loads custom type' do
        user = user_class.new('John')
        obj = klass.create(user: user)

        expect(obj.user).to eql(user)
        expect(reload(obj).user).to eql(user)
        expect(raw_attributes(obj)[:user]).to eql('John')
      end
    end

    context 'DynamoDB type specified' do
      let(:user_class) do
        Class.new do
          attr_accessor :name

          def initialize(name)
            self.name = name
          end

          def eql?(other)
            name == other.name
          end
        end
      end

      let(:adapter) do
        Class.new.tap do |c|
          c.class_exec(user_class) do |user_class|
            @user_class = user_class

            def self.dynamoid_dump(user)
              user.name.split
            end

            def self.dynamoid_load(array)
              array = array.name.split if array.is_a?(@user_class)
              @user_class.new(array.join(' '))
            end

            def self.dynamoid_field_type
              :array
            end
          end
        end
      end

      let(:klass) do
        new_class(adapter: adapter) do |options|
          field :user, options[:adapter]
        end
      end

      it 'stores converted value in a specified type' do
        user = user_class.new('John Doe')
        obj = klass.create(user: user)

        expect(obj.user).to eql(user)
        expect(reload(obj).user).to eql(user)
        expect(raw_attributes(obj)[:user]).to eql(%w[John Doe])
      end
    end
  end
end
