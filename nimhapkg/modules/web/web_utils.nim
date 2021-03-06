# Copyright 2018 - Thomas T. Jarløv

# Copyright 2018 - Thomas T. Jarløv

import osproc, strutils, asyncdispatch, json

import ../../resources/database/database
import ../../resources/mqtt/mqtt_func
import ../web/web_certs

var dbWeb = conn("dbWeb.db")

proc webParseMqtt*(payload: string) {.async.} =
  ## Parse OS utils MQTT

  let js = parseJson(payload)

  if js["item"].getStr() == "certexpiry":
    if js.hasKey("server"):
      asyncCheck certExpiraryJson(js["server"].getStr(), js["port"].getStr())

    else:
      asyncCheck certExpiraryAll(dbWeb)

certDatabase(dbWeb)