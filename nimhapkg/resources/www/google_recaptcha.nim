# Copyright 2018 - Thomas T. Jarløv

import recaptcha, parsecfg, asyncdispatch

from os import getAppDir
from strutils import replace
import ../../resources/utils/common


var
  useCaptcha*: bool
  captcha*: ReCaptcha


# Using config.ini
let dict = loadConf("google_recaptcha")

# Web settings
let recaptchaSecretKey = dict.getSectionValue("reCAPTCHA","Secretkey")
let recaptchaSiteKey* = dict.getSectionValue("reCAPTCHA","Sitekey")


proc setupReCapthca*() =
  # Activate Google reCAPTCHA
  if len(recaptchaSecretKey) > 0 and len(recaptchaSiteKey) > 0:
    useCaptcha = true
    captcha = initReCaptcha(recaptchaSecretKey, recaptchaSiteKey)

  else:
    useCaptcha = false


proc checkReCaptcha*(antibot, userIP: string): Future[bool] {.async.} =
  if useCaptcha:
    var captchaValid: bool = false
    try:
      captchaValid = await captcha.verify(antibot, userIP)
    except:
      captchaValid = false

    if not captchaValid:
      return false
      
    else:
      return true
  
  else:
    return true
