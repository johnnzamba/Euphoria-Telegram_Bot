# TELEGRAM BOT

> The compiled script is just a compilation of numerous functions this bot can perform. Have a go!

[![Codecov](https://codecov.io/github/matthewhudson/words/branch/main/graph/badge.svg?token=oxazfuInJ9)](https://codecov.io/github/johnnzamba/Euphoria-Telegram_Bot)

### Actual Bot Demo

<a href="https://64.media.tumblr.com/c2352b91f89b60267935ef0017916167/511e377b7c399ca9-fc/s540x810/c90bd1b71ae2d005f90df88c8887d3fe304af7d0.pnj"><img src="https://64.media.tumblr.com/c2352b91f89b60267935ef0017916167/511e377b7c399ca9-fc/s540x810/c90bd1b71ae2d005f90df88c8887d3fe304af7d0.pnj"/></a>
<br>
<a href="https://64.media.tumblr.com/cbaad6c005e8c6d16aed6d2dc17f263c/511e377b7c399ca9-4d/s540x810/4f6cd659cef2d33a0cef50aa3c8247b4fb87baaa.pnj"><img src="https://64.media.tumblr.com/cbaad6c005e8c6d16aed6d2dc17f263c/511e377b7c399ca9-4d/s540x810/4f6cd659cef2d33a0cef50aa3c8247b4fb87baaa.pnj"/></a>
<br>
<a href="https://64.media.tumblr.com/ee6f861c2cf9370639b97a4f7f6b1bbd/511e377b7c399ca9-01/s540x810/9db2cbf8e5f5916fc27e61e6bd520e35da62d5b1.pnj"><img src="https://64.media.tumblr.com/ee6f861c2cf9370639b97a4f7f6b1bbd/511e377b7c399ca9-01/s540x810/9db2cbf8e5f5916fc27e61e6bd520e35da62d5b1.pnj"/></a>
<br>
<a href="https://64.media.tumblr.com/85cdc1ac7a1aec9cb73c7ccc80673ad4/511e377b7c399ca9-b2/s540x810/013172b0072473ce666e521be93f4d2be204e505.pnj"><img src="https://64.media.tumblr.com/85cdc1ac7a1aec9cb73c7ccc80673ad4/511e377b7c399ca9-b2/s540x810/013172b0072473ce666e521be93f4d2be204e505.pnj"/></a>
<br>
<a href="https://64.media.tumblr.com/48108969e6a5e69bb2fe0790fcd0fade/511e377b7c399ca9-b6/s540x810/3066a5cd8aeb8765b6055617b97feba71ffe0b0c.pnj"><img src="https://64.media.tumblr.com/48108969e6a5e69bb2fe0790fcd0fade/511e377b7c399ca9-b6/s540x810/3066a5cd8aeb8765b6055617b97feba71ffe0b0c.pnj"/></a>
<br>
<a href="https://64.media.tumblr.com/f3ce86474c73aa45d244cbe48273b946/511e377b7c399ca9-96/s540x810/fe24dd774bab3197500bc4cc308d732002b65663.pnj"><img src="https://64.media.tumblr.com/f3ce86474c73aa45d244cbe48273b946/511e377b7c399ca9-96/s540x810/fe24dd774bab3197500bc4cc308d732002b65663.pnj"/></a>
<br>
<a href="https://64.media.tumblr.com/088f0ce4ffe1323d7d2e62fc590ff918/511e377b7c399ca9-a4/s540x810/548cc85e2eae4a8fdb41fd5c37131e1617db690d.pnj"><img src="https://64.media.tumblr.com/088f0ce4ffe1323d7d2e62fc590ff918/511e377b7c399ca9-a4/s540x810/548cc85e2eae4a8fdb41fd5c37131e1617db690d.pnj"/></a>
<br>
<a href="https://64.media.tumblr.com/bdafbea7728c3a8b94d7377097ae34ad/511e377b7c399ca9-53/s540x810/93c496d04629f59a74f44564963630667e460e74.pnj"><img src="https://64.media.tumblr.com/bdafbea7728c3a8b94d7377097ae34ad/511e377b7c399ca9-53/s540x810/93c496d04629f59a74f44564963630667e460e74.pnj"/></a>
<br>
<a href="https://64.media.tumblr.com/b55f11b43edb19e05d4563d5b8a07870/511e377b7c399ca9-bf/s540x810/2733e5ff197fe57f618f9eeccf21f3cd7bea0c4c.pnj"><img src="https://64.media.tumblr.com/b55f11b43edb19e05d4563d5b8a07870/511e377b7c399ca9-bf/s540x810/2733e5ff197fe57f618f9eeccf21f3cd7bea0c4c.pnj"/></a>
<br>
## Installation

For Starters go to telegram and find [@botFather](https://core.telegram.org/bots#botfather) and register a new bot. Save the new Telegram Bot Token and replace it in the ENV file.
The necessary instructions for API's are in the file as well.

Then to now access the script:

```bash
git clone https://github.com/johnnzamba/Euphoria-Telegram_Bot.git
```
```bash
cd Euphoria-Telegram_Bot
```

Ensure you have  RVM (Ruby Version Manager)in order to set up ruby. If not, visit [this link](https://rvm.io/rvm/install)

```bash
ruby --version
```
```bash
gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
```
```bash
\curl -sSL https://get.rvm.io | bash -s stable --ruby
```
```bash
gem install bundler
```
Now in the Project Directory; the Gemfile contains necessary gems for the project. Run the following command to install all the necessary gems:

```bash
bundle install
```

## Usage
Now the scripts can be run locally or on a server; 
To execute the script locally, run the following command:
```bash
bundle exec ruby main.rb
```
Please Note that the required APIs and Tokens are to be replaced in the ENV file.

## Acknowledgement

I want to acknowledge that this project is solely owned by me. All rights, including intellectual property rights, are retained by the original owner. The code, design, and any associated content are proprietary. For any inquiries, Please contact me at [#{nzambakitheka@gmail.com}](mailto:#{nzambakitheka@gmail.com}).

Thank you for your understanding and respect for the intellectual property rights associated with this project.


## License

Unless attributed otherwise, everything is under the MIT License (see LICENSE for more info).
