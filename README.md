# SlackSpace

A Slack integration to send Rackspace Monitoring alarm notifications to a Slack channel.

SlackSpace is a Ruby/Sinatra app that receives webhook notifications from Rackspace,
translates them into something Slack can work with,
and pushes them to a Slack incoming-webhook URL.

You can download this app and run it on your own server,
or you can use a live demo of this app running on Heroku.

Note that this app:

* Does not save any of your information.
* Does not access information in your Slack accounts or Rackspace accounts.
* Is a translator running between Rackspace notifications and Slack incoming webhooks.
* Is currently ALPHA. Functionality is mostly stable, API is not.

### Use the Demo

* Create an incoming webhook on Slack for your team.
* Copy the URI path of the webhook, just the part with the encrypted key,
  including the slashes within, but not the 'http://host.domain.com' part.
  Ex: nfheus98Hnb/HYGGLPzy6/nNHJKC&BW6tgfcu
* Create a webhook notification on Rackspace with this url:

        https://slackspace.herokuapp.com/slack/webhook/?key=<your/unique/incoming/webhook/key>

* Attach the Rackspace notification to an alarm of one of your Rackspace monitors.
  See the Rackspace Intelligence section of your account for API and help.
    

### Run this app on your own server

* Download the app.
* Bundle install
* Bundle exec rackup, or whatever commands you use to boot apps.
* Point your Rackspace notification webhook url to this app:

        https://your.custom.domain/slack/webhook/?key=<your/unique/incoming/webhook/key>


### License

This software is licensed under The MIT License (MIT). This software is not provided by or endorsed in any way by Slack or Rackspace.

Copyright (c) 2015 William Richardson.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.