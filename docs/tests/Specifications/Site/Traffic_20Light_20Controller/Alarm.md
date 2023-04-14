---
layout: page
title: Alarm
parmalink: traffic_light_controller_alarm
has_children: false
has_toc: false
parent: Traffic Light Controller
grand_parent: Site
---

# Traffic Light Controller Alarm
{: .no_toc}

Testing alarms require a reliable way of rainsing them.

There's no way to trigger alarms directly via RSMP yet,
but often you can program the equipment to raise an alarm
when a specific input is activated. If that's the case,
set the `alarm_activcation` item in the validator config to
specify which input activates which alarm. See docs for details.

Triggered alarms manually on the equipment is not used,
because validator is meant for automated testing.

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Alarm A0302 is raised when a detector logic is faulty

Validate that a detector logic fault A0302 is raises and cleared.

The test requires that the device is programmed so that the alarm
is raise when a specific input is activated, as specified in the
test configuration.

1. Given the site is connected
2. When we force the input to True
3. Then an alarm should be raised, with a timestamp close to now
4. When we force the input to False
5. Then the alarm issue should become inactive, with a timestamp close to now

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  alarm_code_id = 'A0302'
  prepare task, site
  def verify_timestamp alarm, duration=1.minute
    alarm_time = Time.parse(alarm.attributes["aTs"])
    expect(alarm_time).to be_within(duration).of Time.now.utc
  end
  deactivate = with_alarm_activated(task, site, alarm_code_id) do |alarm|   # raise alarm, by activating input
    verify_timestamp alarm
    log "Alarm #{alarm_code_id} is now Active"
  end
  verify_timestamp deactivate
  log "Alarm #{alarm_code_id} is now Inactive"
end
```
</details>




## Alarm Alarm A0301 is raised when input is activated

Validate that a detector logic fault A0301 is raises and cleared.

The test requires that the device is programmed so that the alarm
is raise when a specific input is activated, as specified in the
test configuration.

1. Given the site is connected
2. When we force the input to True
3. Then an alarm should be raised, with a timestamp close to now
4. When we force the input to False
5. Then the alarm issue should become inactive, with a timestamp close to now

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  alarm_code_id = 'A0301'
  prepare task, site
  def verify_timestamp alarm, duration=1.minute
    alarm_time = Time.parse(alarm.attributes["aTs"])
    expect(alarm_time).to be_within(duration).of Time.now.utc
  end
  deactivate = with_alarm_activated(task, site, alarm_code_id) do |alarm|   # raise alarm, by activating input
    verify_timestamp alarm
    log "Alarm #{alarm_code_id} is now Active"
  end
  verify_timestamp deactivate
  log "Alarm #{alarm_code_id} is now Inactive"
end
```
</details>




## Alarm can be acknowledged

Validate that an alarm can be acknowledged.

1. Given the site is connected
2. When we raise an alarm, by acticating an input
3. Then we should receive an alarm
4. When we acknowledgement the alarm
5. Then we should receive a confirmation

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
skip "Test case not ready"
Validator::Site.connected do |task,supervisor,site|
  @site = site
  with_alarm_activated task, site, 'A0301' do |alarm|
    # TODO verify that we can acknowledge the alarm
  end
end
```
</details>


