RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::StatusHelpers
  include Validator::CommandHelpers

  describe "Operational" do
    # Verify status S0020 control mode
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'control mode is read with S0020', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "control mode",
        { S0020: [:controlmode,:intersection] }
    end

    # Verify status S0005 traffic controller starting
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'startup status is read with S0005', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "traffic controller starting (true/false)",
        { S0005: [:status] }
    end

    # Verify status S0006 emergency stage
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'emergency stage is read with S0006', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "emergency stage status",
        { S0006: [:status,:emergencystage] }
    end

    # Verify status S0007 controller switched on (dark mode=off)
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'switched on is read with S0007', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "controller switch on (dark mode=off)",
        { S0007: [:status,:intersection] }
    end

    # Verify status S0008 manual control
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'manual control is read with S0008', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "manual control status",
        { S0008: [:status,:intersection] }
    end

    # Verify status S0009 fixed time control
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'fixed time control is read with S0009', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "fixed time control status",
        { S0009: [:status,:intersection] }
    end

    # 1. Verify connection
    # 2. Send the control command to switch to  fixed time= true
    # 3. Wait for status = true
    # 4. Send control command to switch "fixed time"= true
    # 5. Wait for status = false
    specify 'fixed time control can be activated with M0007', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        switch_fixed_time 'True'
        switch_fixed_time 'False'
      end
    end

    # Verify status S0010 isolated control
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'isolated control is read with S0010', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "isolated control status",
        { S0010: [:status,:intersection] }
    end

    # Verify status S0011 yellow flash
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'yellow flash can be read with S0011', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "yellow flash status",
        { S0011: [:status,:intersection] }
    end

    # Verify that we can activate yellow flash
    #
    # 1. Given the site is connected
    # 2. Send the control command to switch to Yellow flash
    # 3. Wait for status Yellow flash
    # 4. Send command to switch to normal control
    # 5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"
    specify 'yellow flash can be activated with M0001', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        switch_yellow_flash
        switch_normal_control
      end
    end

    specify 'yellow flash affects all signal groups', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        timeout =  10

        switch_yellow_flash
        wait_for_groups 'c', timeout: timeout      # c mean s yellow flash

        switch_normal_control
        wait_for_groups '[^c]', timeout: timeout   # not c, ie. not yellow flash
      end
    end

    # Verify status S0012 all red
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'all red can be read with S0012', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "all-red status",
        { S0012: [:status,:intersection] }
    end

    # Verify status S0013 police key
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'police key can be read with S0013', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "police key",
        { S0013: [:status] }
    end


    # Verify that we can activate yellow flash
    #
    # 1. Given the site is connected
    # 2. Send the control command to switch to Yellow flash
    # 3. Wait for status Yellow flash
    # 4. Send command to switch to normal control
    # 5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"
    it 'M0001 set yellow flash', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        switch_yellow_flash
        switch_normal_control
      end
    end

        # Verify that we can activate normal control after yellow flash mode
    #
    # 1. Given the site is connected and in yellow flash mode
    # 2. Send the control command to switch to normal control
    # 3. Wait for S0020 status "startup" 
    # 4. Wait for S0001 status "eeeee"
    # 5. Wait for S0001 status "ffffffff"
    # 6. Wait for S0001 status "gggggg"
    # 7. Wait for S0020 status "control" 
    it 'M0001 startup after yellow flash', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site

        status_list = [
          {'sCI'=>'S0001','n'=>'signalgroupstatus'}
        ]
        subscribe_list = convert_status_list(status_list).map { |item| item.merge 'uRt'=>0.to_s }
        unsubscribe_list = convert_status_list(status_list)

        component = Validator.config['main_component']
        timeout = Validator.config['timeouts']['command']
        collector = RSMP::StatusUpdateMatcher.new site, status_list
        sequencer = Validator::StatusHelpers::SequenceHelper.new 'efg'
        states = nil
        seq_timeout = 7

        collect_task = task.async do     # start an asyncronous task
          collector.collect(task, timeout: seq_timeout) do |message,item|   # listen for status messages
            states = message.attribute('sS').first['s']
            begin
              sequencer.check states      # check sequences?
              site.log "Checking startup sequence, #{states}: OK", level: :test
              puts "Checking startup sequence, #{states}: OK"
              sequencer.done?        # done if all groups reached end
            rescue Validator::StatusHelpers::SequenceError => e
              site.log "Checking startup sequence, #{states}: Fail", level: :test
              puts "Checking startup sequence, #{states}: Fail"
              false
            end
          end
        end
        begin
          @site.subscribe_to_status component, subscribe_list  # subscribe, so we start getting status udates
          switch_yellow_flash
          switch_normal_control

          collect_task.wait  # wait for the collector to complete. if the async task raised an error it will be reraised
        rescue RSMP::TimeoutError => e
          if states
            raise "Startup sequence didn't complete in #{seq_timeout}s, #{sequencer.num_started}/#{states.size} initiated, #{sequencer.num_done}/#{states.size} done"
          else
            raise "No signal group status was received."
          end
        ensure
          @site.unsubscribe_to_status component, unsubscribe_list  # unsubscribe
          set_functional_position 'NormalControl'
        end
      end
    end

    # Verify that we can activate dark mode
    #
    # 1. Given the site is connected
    # 2. Send the control command to switch todarkmode
    # 3. Wait for status"Controller on" = false
    # 4. Send command to switch to normal control
    # 5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"
    specify 'dark mode can be activated with M0001', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        switch_dark_mode
        switch_normal_control
      end
    end

    # 1. Verify connection
    # 2. Send the control command to switch to  fixed time= true
    # 3. Wait for status = true
    # 4. Send control command to switch "fixed time"= true
    # 5. Wait for status = false
    it 'M0007 set fixed time with added status check', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        switch_fixed_time 'True'
        wait_for_status(@task,"Fixed time control active", [{'sCI'=>'S0009','n'=>'status','s'=>'True'}])
        wait_for_status(@task,"signalgroupstatus A or B", [{'sCI'=>'S0001','n'=>'signalgroupstatus','s'=>/^[AB]$/}])
        switch_fixed_time 'False'
      end
    end
  end
end

