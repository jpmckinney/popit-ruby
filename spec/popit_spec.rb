require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'yaml'

# We don't want to test the PopIt API. We want to check that the wrapper works.
#
# @see https://github.com/mysociety/popit/blob/master/lib/apps/api/api_v1.js
describe PopIt do
  let :unauthenticated do
    PopIt.new :instance_name => 'tttest'
  end

  let :authenticated do
    PopIt.new credentials
  end

  it 'should fail to send a request to a bad instance' do
    api = PopIt.new :instance_name => '47cc67093475061e3d95369d'
    expect { api.person.get }.to raise_error(PopIt::Error, '404')
  end

  it 'should fail to send a request to a bad version' do
    api = PopIt.new :instance_name => 'tttest', :version => 'v0'
    expect { api.person.get }.to raise_error(PopIt::Error, '{"error":"page not found"}')
  end

  context 'with a PopIt instance' do
    before :all do
      @person = unauthenticated.person.get(:name => 'Foo', :slug => 'foo')['results'][0]
    end

    let :person do
      @person
    end

    let :id do
      @person['_id']
    end

    it 'should fail to send a request to a bad schema' do
      expect { unauthenticated.foo.get }.to raise_error(PopIt::Error, '{"error":"page not found"}')
    end

    context 'when unauthenticated' do
      p ENV['INSTANCE_NAME']
      it 'should get all items' do
        response = unauthenticated.person.get
        results = response['results']
        results.should be_an(Array)
      end

      it 'should get one item by name' do
        response = unauthenticated.person.get :name => 'Foo'
        results = response['results']
        results.should be_an(Array)
      end

      it 'should get one item' do
        response = unauthenticated.person(id).get
        result = response['result']
        # PopIt adds fields e.g. __v, _internal, contact_details, images, links,
        # other_names, personal_details and adds positions_api_url to meta.
        person.each do |k,v|
          unless k == 'meta'
            result[k].should == v
          end
        end
      end

      it 'should fail to get a non-existent item' do
        expect { unauthenticated.person('bar').get }.to raise_error(PopIt::Error, '{"error":"page not found"}')
      end

      it 'should fail to create an item' do
        expect {unauthenticated.person.post :name => 'John Doe', :slug => 'john-doe'}.to raise_error(PopIt::Error, %({"error":"not authenticated"}))
      end

      it 'should fail to update an item' do
        expect {unauthenticated.person(id).put :name => 'Jane Doe'}.to raise_error(PopIt::Error, %({"error":"not authenticated"}))
      end

      it 'should fail to delete an item' do
        expect {unauthenticated.person(id).delete}.to raise_error(PopIt::Error, %({"error":"not authenticated"}))
      end
    end

    context 'when authenticated', :if => credentials? do
      it 'should create an item' do
        response = authenticated.person.post :name => 'John Smith'
        result = response['result']
        result['name'].should == 'John Smith'
        authenticated.person(result['_id']).delete # cleanup
      end

      it 'should update an item' do
        response = authenticated.person(id).put :name => 'John Smith'
        response.should == nil
      end

      it 'should delete an item' do
        response = authenticated.person(id).delete
        response.should == {}
      end
    end
  end
end
