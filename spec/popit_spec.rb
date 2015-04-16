require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'yaml'

# We don't want to test the PopIt API. We want to check that the wrapper works.
#
# @see https://github.com/mysociety/popit/blob/master/lib/apps/api/api_v1.js
describe PopIt do
  let :unauthenticated do
    PopIt.new(:instance_name => 'tttest')
  end

  let :authenticated do
    PopIt.new({
      :instance_name => ENV['INSTANCE_NAME'] || 'tttest',
      :apikey        => ENV['POPIT_API_KEY'],
    })
  end

  let :exponential_backoff do
    PopIt.new(:instance_name => 'tttest', :max_retries => 2)
  end

  it 'should fail to send a request to a bad instance' do
    api = PopIt.new(:instance_name => '47cc67093475061e3d95369d')
    expect { api.persons.get }.to raise_error(PopIt::PageNotFound)
  end

  it 'should fail to send a request to a bad version' do
    api = PopIt.new(:instance_name => 'tttest', :version => 'v0')
    expect { api.persons.get }.to raise_error(PopIt::PageNotFound, 'page not found')
  end

  context 'with a PopIt instance' do
    let :person do
      unauthenticated.persons.get(:name => 'Foo', :slug => 'foo')[0]
    end

    let :id do
      person['id']
    end

    it 'should fail to send a request to a bad schema' do
      expect { unauthenticated.foo.get }.to raise_error(PopIt::PageNotFound, "collection 'foo' not found")
    end

    context 'when unauthenticated' do
      it 'should get all items' do
        response = unauthenticated.persons.get
        expect(response).to be_an(Array)
      end

      it 'should get one item by name' do
        response = unauthenticated.persons.get(:name => 'Foo')
        expect(response).to be_an(Array)
      end

      it 'should get one item' do
        response = unauthenticated.persons(id).get
        # PopIt adds fields e.g. __v, _internal, contact_details, images, links,
        # other_names, personal_details and adds positions_api_url to meta.
        person.each do |k,v|
          unless k == 'meta'
            expect(response[k]).to eq(v)
          end
        end
      end

      it 'should fail to get a non-existent item' do
        expect {unauthenticated.persons('bar').get}.to raise_error(PopIt::PageNotFound, "id 'bar' not found")
      end

      it 'should fail to create an item' do
        expect {unauthenticated.persons.post(:name => 'John Doe', :slug => 'john-doe')}.to raise_error(PopIt::NotAuthenticated)
      end

      it 'should fail to update an item' do
        expect {unauthenticated.persons(id).put(:id => id, :name => 'John Doe', :slug => 'john-doe')}.to raise_error(PopIt::NotAuthenticated)
      end

      it 'should fail to delete an item' do
        expect {unauthenticated.persons(id).delete}.to raise_error(PopIt::NotAuthenticated)
      end
    end

    context 'when authenticated' do
      it 'should create, update and delete an item' do
        response = authenticated.persons.post(:name => 'John Smith', :slug => 'john-smith', :contact_details => [{:type => 'email', :value => 'test@example.com'}])
        id = response['id']
        contact_detail_id = response['contact_details'][0]['id']
        expect(response['name']).to eq('John Smith')

        response = authenticated.persons(id).put(:id => id, :name => 'John Doe', :slug => 'john-doe')
        expect(response).to eq({
          'id'              => id,
          'name'            => 'John Doe',
          'slug'            => 'john-doe',
          'memberships'     => [],
          'links'           => [],
          'contact_details' => [{
            'type'  => 'email',
            'value' => 'test@example.com',
            'id'    => contact_detail_id,
          }],
          'identifiers'     => [],
          'images'          => [],
          'other_names'     => [],
          'url'             => 'https://tttest.popit.mysociety.org/api/v0.1/persons/' + id,
          'html_url'        => 'https://tttest.popit.mysociety.org/persons/' + id,
        })
        expect(authenticated.persons(id).get['name']).to eq('John Doe')

        response = authenticated.persons(id).delete
        expect(response).to be_nil
        sleep 5 # doesn't get deleted right away
        expect {authenticated.persons(id).get}.to raise_error(PopIt::PageNotFound, "id '#{id}' not found")
      end
    end

    context 'when service unavailable' do
      before :each do
        allow(PopIt).to receive(:get) do
          response = Net::HTTPServiceUnavailable.new('1.1', 503, 'Service Unavailable')
          allow(response).to receive_messages(:body => '', :code => '503')
          HTTParty::Response.new(HTTParty::Request.new(Net::HTTP::Get, '/'), response, lambda {})
        end
      end

      it 'should fail immediately' do
        time = Time.now
        expect {unauthenticated.persons.get}.to raise_error(PopIt::ServiceUnavailable)
        expect(Time.now).to be_within(1).of(time)
      end

      it 'should backoff exponentially' do
        time = Time.now
        expect {exponential_backoff.persons.get}.to raise_error(PopIt::ServiceUnavailable)
        expect(Time.now).to_not be_within(5).of(time)
      end
    end
  end
end
