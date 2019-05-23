# Copyright 2018 - Thomas T. Jarløv
#
# Todo: Implement nim solution instead of curl

import asyncdispatch

import db_sqlite, osproc, json, strutils, parsecfg
import ../database/database
import ../mqtt/mqtt_func


var dbMqtt = conn("dbMqtt.db")


proc mqttActionSendDb*(mqttActionID: string) =
  ## Sends a MQTT message from database

  let action = getRow(dbMqtt, sql"SELECT topic, message FROM mqtt_templates WHERE id = ?", mqttActionID)

  asyncCheck mqttSendAsync("mqttaction", action[0], action[1])
