# SlackSpace

A Slack integration to send Rackspace Monitoring alarm notifications to a Slack channel.

SlackSpace is a Ruby/Sinatra app that receives webhook notifications from Rackspace,
translates them into something Slack can work with, and pushes them to a Slack
incomming-webhook URL.

You can download this app and run it on your own server, or you can use a live demo of this app running on Heroku.

Note that this app does not save any of your information. Nor does it have any access to information in your Slack account(s) or your Rackspace account(s). This app is merely a translator running between Rackspace and Slack.

### Use the Demo

* Create an incomming webhook for your slack team.
* Copy the URI path of the webhook (just the part with the encrypted key, including the slashes within).
* Create a webhook notification on Rackspace with this url:

        https://slackspace.herokuapp.com/slack/webhook/?key=<your/unique/incomming/webhook/key>

* Attach the Rackspace notification to an alarm of one of your Rackspace monitors.
    

### Run this app on your own server

* Download the app.
* Bundle install
* Bundle exec rackup - or whatever commands are necessary for your application server.
* Point your Rackspace notification webhook url to this app:

        https://your.custom.domain/slack/webhook/?key=<your/unique/incomming/webhook/key>


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