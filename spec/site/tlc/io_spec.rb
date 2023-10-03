RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::CommandHelpers
  include Validator::StatusHelpers

  # Tests related to inputs and outputs.

  describe 'IO' do
    describe 'Input' do
      # Verify that we can read force status with S0029
      #
      # 1. Given the site is connected
      # 2. When we request force status
      # 3. We should receive a status response
      specify 'forcing is read with S0029', sxl: '>=1.0.13' do |example|
        Validator::Site.connected do |task,supervisor,site|
         request_status_and_confirm site, "forced input status",
            { S0029: [:status] }
        end
      end

      # Verify that we can force input wit M0019
      #
      # 1. Given the site is connected
      # 2. And the input is forced off
      # 3. When we force the input on with M00019
      # 4. Then S0029 should show the input is forced
      # 5. And S0029 should the input is on
      specify 'is forced with M0019', sxl: '>=1.0.13' do |example|
        Validator::Site.connected do |task,supervisor,site|
          prepare task, site
          input = Validator.config['items']['force_input']

          # force input off
          status = 'True'
          inputValue = 'False'
          force_input status:status, input:input, value:inputValue
          
          # wait for input being forces
          wait_for_status(@task,
            "input #{input} to be forced",
            [{'sCI'=>'S0029','n'=>'status','s'=>/^.{#{input - 1}}1/}]
          )

          # wait for input being off
          wait_for_status(@task,
            "input #{input} to be #{inputValue}",
            [{'sCI'=>'S0003','n'=>'inputstatus','s'=>/^.{#{input - 1}}0/}]
          )


          # force input on
          status = 'True'
          inputValue = 'True'
          force_input status:status, input:input, value:inputValue
          
          # wait for input being forced
          wait_for_status(@task,
            "input #{input} to be forced",
            [{'sCI'=>'S0029','n'=>'status','s'=>/^.{#{input - 1}}1/}]
          )

          # wait for input being on
          wait_for_status(@task,
            "input #{input} to be to #{inputValue}",
            [{'sCI'=>'S0003','n'=>'inputstatus','s'=>/^.{#{input - 1}}1/}]
          )

        ensure
          # release input
          status = 'False'
          inputValue = 'False'
          force_input status:status, input:input, value:inputValue

          # wait for input being released
          wait_for_status(@task,
            "input #{input} to be released",
            [{'sCI'=>'S0029','n'=>'status','s'=>/^.{#{input - 1}}0/}]
          )
        end
      end

      # Verify that we can acticate input with M0006
      #
      # 1. Given the site is connected
      # 2. When we activate the input with M0006
      # 3. Then S0003 should show the input is active
      # 2. When we deactivate the input with M0006
      # 3. Then S0003 should show the input is inactive
      it 'is activated with M0006', sxl: '>=1.0.7' do |example|
        inputs = Validator.config['items']['inputs']
        skip("No inputs configured") if inputs.nil? || inputs.empty?
        Validator::Site.connected do |task,supervisor,site|
          prepare task, site
          inputs.each { |input| switch_input input }
        end
      end

      # Verify that we can acticate a series of inputs with M0013
      #
      # 1. Given the site is connected
      # 2. When we activate a series of input with M0013
      # 3. Then S0003 should show the inputs are active
      # 2. When we deactivate the input with M0006
      # 3. Then S0003 should show the correct inputs being active

      # 1. Verify connection
      # 2. Send control command to set a serie of input
      # 3. Wait for status = true
      specify 'series is activated with M0013', sxl: '>=1.0.8' do |example|
        Validator::Site.connected do |task,supervisor,site|
          prepare task, site
          set_series_of_inputs "1,0,255"
          set_series_of_inputs "1,3,12;5,5,10"

          wait_for_status(@task,
            "inputs [1, 2, 5, 7] to be active and inputs [3, 4, 6, 8] to be inactive",
            [{'sCI'=>'S0003','n'=>'inputstatus','s'=>/^1100101/}]
          )
        end
      end

      # Verify that we can set sensitivity level
      # 1. Given the site is connected
      # 2. When we set sensitivity with M0021
      # 3. We get a confirmation
      specify 'sensitivity is set with M0021', sxl: '>=1.0.15' do |example|
        Validator::Site.connected do |task,supervisor,site|
          prepare task, site
          status = '1-50'
          set_trigger_level status
        end
      end
    end

    describe 'Output' do
      # 1. Given the site is connected
      # 2. When we subscribe to S0004
      # 3. We should receive a status updated
      # 4. And the outputstatus attribute should be a digit string
      specify 'can be read with S0004', sxl: '>=1.0.7' do |example|
        Validator::Site.connected do |task,supervisor,site|
          prepare task, site
          wait_for_status(@task,
            "S0003 status",
            [{'sCI'=>'S0004','n'=>'outputstatus','s'=>/^[01]*/}]
          )
        end
      end

      # Verify status S0030 forced output status
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      specify 'forcing is read with S0030', sxl: '>=1.0.15' do |example|
        Validator::Site.connected do |task,supervisor,site|
          request_status_and_confirm site, "forced output status",
            { S0030: [:status] }
        end
      end

      # 1. Verify connection
      # 2. Send control command to set force ounput
      # 3. Wait for status = true
      specify 'forcing is set with M0020', sxl: '>=1.0.15' do |example|
        Validator::Site.connected do |task,supervisor,site|
          status = 'False'
          output = 1
          outputValue = 'True'
          prepare task, site
          force_output status, output, outputValue
        end
      end
    end
  end
end
