# Copyright 2018 - Thomas T. Jarløv


import parsecfg, db_sqlite, strutils, asyncdispatch, json, times
from os import sleep

import ../resources/database/database
import ../modules/mail/mail
import ../modules/os/os_utils
import ../resources/mqtt/mqtt_templates
import ../modules/pushbullet/pushbullet
when defined(rpi):
  import ../modules/rpi/rpi_utils
import ../modules/xiaomi/xiaomi_utils
import ../resources/utils/log_utils


var db = conn("dbCron.db")



#[
type
  Cronjob = ref object
    element: string
    jobid: string
    time: string
    active: bool

  Cron = ref object
    cronjobs: seq[Cronjob]


var cron = Cron(cronjobs: @[])


proc newCronjob(element, jobid, time, active: string): Cronjob =
  ## Generate new cronjob

  return Cronjob(
    element: element,
    jobid: jobid,
    time: time,
    active: parseBool(active)
  )


proc cronUpdateJobs() =
  ## Update the cronjob container

  let cronActions = getAllRows(db, sql"SELECT element, action_ref, time, active FROM cron_actions")

  var newCronjobs: seq[Cronjob] = @[]
  for row in cronActions:
    if row[3] == "false":
      continue

    newCronjobs.add(newCronjob(row[0], row[1], row[2], row[3]))

  cron.cronjobs = newCronjobs


proc cronJobRun() {.async.} =
  ## Run the cron jobs

  let cronTime = format(local(now()), "HH:mm")
  echo format(local(now()), "HH:mm:ss")
  if cron.cronjobs.len() > 0:
    sleep(5000)
    var newCronjobs: seq[Cronjob] = @[]
    for cronitem in cron.cronjobs:
      if not cronitem.active:
        continue

      # Add job to seq
      newCronjobs.add(cronitem)

      # Check time. If hour and minut fits (24H) then go
      if cronTime != cronitem.time:
        continue

      cronitem.active = false

      case cronitem.element
      of "pushbullet":
        echo "push"
        pushbulletSendDb(cronitem.jobid)

      of "mail":
        sendMailDb(cronitem.jobid)

      of "xiaomi":
        asyncCheck xiaomiWriteTemplate(db, cronitem.jobid)

      else:
        discard

    # Update seq - exclude non active
    cron.cronjobs = newCronjobs
]#


proc cronJobRun(time: string) =
  ## Run the cron jobs

  let cronActions = getAllRows(db, sql"SELECT element, action_ref FROM cron_actions WHERE active = ? AND time = ?", "true", time)

  if cronActions.len() == 0:
    return

  logit("cron", "DEBUG", "Executing cron activities. Total number: " & $cronActions.len())

  for row in cronActions:

    case row[0]
    of "pushbullet":
      pushbulletSendDb(row[1])

    of "mail":
      sendMailDb(row[1])

    of "os":
      asyncCheck osRunTemplate(row[1])

    of "mqtt":
      mqttActionSendDb(row[1])

    of "rpi":
      when defined(rpi):
        discard rpiAction(row[1])

    of "xiaomi":
      ## TODO: This leads to error sometimes
      xiaomiWriteTemplate(row[1])

    else:
      discard



proc cronJob() =
  ## Run the main cron job
  ##
  ## Check every minute if an action is required
  ##
  ## Currently using sleep - should it be sleepAsync
  ## and moved inside another main module? SleepAsync
  ## messes up the RPi CPU

  logit("cron", "INFO", "Cron main started")


  while true:

    cronJobRun(format(local(now()), "HH:mm"))

    # Wait before next cron check
    # Get current seconds, subtract from 60 to
    # get next starting minute and sleep. This
    # will accept that we are blocking using sleep

    let sleepTime = 60 - parseInt(format(local(now()), "ss"))

    sleep(sleepTime * 1000)



when isMainModule:
  cronJob()
  runForever()
