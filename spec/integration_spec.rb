require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# Loading the Dummy Rails App
require File.expand_path('../spec/dummy/config/environment.rb', __dir__)
ENV['RAILS_ROOT'] ||= File.dirname(__FILE__) + '../../../spec/dummy'
require 'rspec/rails'

describe 'integration' do
  it "supports all common fields" do
    utf8_stress_test = <<-STRESS
ăѣ𝔠ծềſģȟᎥ𝒋ǩľḿꞑȯ𝘱𝑞𝗋𝘴ȶ𝞄𝜈ψ𝒙𝘆𝚣1234567890!@#$%^&*()-_=+[{]};:'",<.>/?~𝘈Ḇ𝖢𝕯٤ḞԍНǏ𝙅ƘԸⲘ𝙉০Ρ𝗤Ɍ𝓢ȚЦ𝒱Ѡ𝓧ƳȤѧᖯć𝗱ễ𝑓𝙜Ⴙ𝞲𝑗𝒌ļṃŉо𝞎𝒒ᵲꜱ𝙩ừ𝗏ŵ𝒙𝒚ź1234567890!@#$%^&*()-_=+[{]};:'",<.>/?
    STRESS

    factory = RGeo::Geographic.simple_mercator_factory()
    polygon = factory.parse_wkt("POLYGON((0.5 0.5,5 0,5 5,0 5,0.5 0.5), (1.5 1,4 3,4 1,1.5 1))")
    t1 = Time.new(2002, 10, 31, 12, 5, 1).utc
    t2 = Time.new(1985, 10, 31, 3, 4, 5).utc
    inet = IPAddr.new("192.168.1.12")
    cidr =IPAddr.new("192.168.2.0/24")

    mac_addr = "32:01:16:6d:05:ef"
    MyModel.delete_all
    columns = [
      :binary,
      :bigint,
      :boolean,
      :date,
      :datetime,
      :timestamp,
      :time,
      :decimal,
      :float,
      :integer,
      :text,
      :geometry,
      :json,
      :jsonb,
      :inet,
      :cidr,
      :macaddr
    ]
    MyModel.copy_from_client(columns) do |csv|
      1000.times do
        csv << ["42", 9223372036854775807, true, t1, t1, t1, t1, 4242.42, 4242.42, 42, "this is some text", factory.point(1, 2), { a: 1 }, { a: 1 }, inet, cidr, mac_addr]
        csv << ["1", -9223372036854775808, false, t2, t2, t2, t2, -4242.42, 4242.42, -42, utf8_stress_test, polygon, [{ a: 1 }], [{ a: 1 }], inet.to_s, cidr.to_s, "32-01-16-6D:05-EF"]
      end
    end

    expect(MyModel.count).to be 2000

    first = MyModel.first

    expect(first.time.hour).to eq(t1.hour)
    expect(first.time.min).to eq(t1.min)
    expect(first.time.sec).to eq(t1.sec)

    expect(first.attributes.symbolize_keys).to(
      include(
        binary: "42",
        bigint: 9223372036854775807,
        decimal: 4242.42,
        boolean: true,
        date: t1.to_date,
        time: Time.new(2000, 1, 1, 12, 5, 1).utc,
        timestamp: t1,
        datetime: t1,
        integer: 42,
        text: "this is some text",
        geometry: factory.point(1, 2),
        json: { "a" => 1 },
        jsonb: { "a" => 1 },
        inet: inet,
        cidr: cidr,
        macaddr: mac_addr
      )
    )
    second = MyModel.second

    expect(second.time.hour).to eq(t2.hour)
    expect(second.time.min).to eq(t2.min)
    expect(second.time.sec).to eq(t2.sec)

    expect(MyModel.second.attributes.symbolize_keys).to(
      include(
        binary: "1",
        bigint: -9223372036854775808,
        decimal: -4242.42,
        boolean: false,
        time: Time.new(2000, 1, 1, 3, 4, 5).utc,
        date: t2.to_date,
        datetime: t2,
        timestamp: t2,
        integer: -42,
        text: utf8_stress_test,
        geometry: polygon,
        json: [{ "a" => 1 }],
        jsonb: [{ "a" => 1 }],
        inet: inet,
        cidr: cidr,
        macaddr: mac_addr
      )
    )
  end
end
