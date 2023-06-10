# RSS to listmonk

`rss2listmonk` is a tiny utility that can create email campaigns on listmonk.app with content filled from a RSS feed.

The idea is simple

- You give it a URL to a feed
- You specify the configuration of listmonk
- It does the rest using the listmonk API

## Installation

### Requirements

- Elixir
- A listmonk instance of your own
- (optional) An operating system that can run things periodically (`periodic(8)`, `cron(8)`, etc)

### Steps

Here are some easy steps to install `rss2listmonk`

```console
git clone https://github.com/antranigv/rss2listmonk # Checkout the repo
mix deps.get # Get the dependencies
mix deps.compile # Compile the dependencies
mix compile # Compile rss2listmonk
mix escript.build # Build an escript
```

## Run as a command

By default, the escript will go into the `_build` directory.

```console
$ cd _build
$ ./rss2listmonk
usage: ./rss2listmonk
  --feed https://awesome.blog/feed/
  --listmonk https://listmonk.app
  --user listmonk_user
  --password listmonk_pass
  --template id
  --lists 2,4,5
  [ --subject "Awesome blog $(date)" ]
  [ --from 'Awesome Blogger <newsletter@example.com>' ]
  [ --reply-to 'John Smithian <john@example.com>' ]
  [ --range 24H ]
  [ --lang en_US ]
  [ --debug ]
  [ --send-later]

```

|      Argument       |                            Value                             |                       Example                        |
| :-----------------: | :----------------------------------------------------------: | :--------------------------------------------------: |
|        feed         |                       path to RSS feed                       |          https://weblog.antranigv.am/feed/           |
|      listmonk       |                  path to listmonk instance                   |            https://newsletter.example.com            |
|        user         |                        listmonk user                         |                        admin                         |
|      password       |                   listmonk user's password                   |                      adminpass                       |
|      template       |            ID of the template in listmonk to use             |                          2                           |
|        lists        |                     Mailing Lists to use                     |                        2,4,5                         |
| subject (optional)  | campaign's subject, defaults to "{Feed's Title}: {today's date}" |                                                      |
|   from (optional)   | the `FROM` email that will be used, defaults to the config's default | 'Awesome Blog Newsletter \<newsletter@example.com\>' |
| reply-to (optional) |     adds a `reply-to` email header, defaults to nothing      |         'John Smithian \<john@example.com\>`         |
|  range (optional)   |      range of the data to fetch from the feed, in hours      |                         72H                          |
|   lang (optional)   | This is used as a `LANG` environment variable for `date(1)` inside the title |                        hy_AM                         |
| debug \| send-later | debug will display the API call, but not send it.<br />send-later will send the API call, but not run the campaign |                                                      |

### Example

```console
./rss2listmonk
	--feed https://weblog.antranigv.am/feed/
	--listmonk http://newsletter.bsd.am
	--user admin
	--password 'adminpass'
	--template 6
	--lists 3
	--subject "%title: $(date +%Y), W$(date +%U)"
	--from 'Antranig Vartanian <newsletter@bsd.am>'
	--reply-to 'Antranig Vartanian <antranig@vartanian.am>'
	--range 168H
```

The campaign will end up looking like this →

```json
{
  "type": "regular",
  "template_id": 6,
  "tags": [
    "blog"
  ],
  "subject": "Freedom Be With All: 2023, W23",
  "send_later": false,
  "send_at": null,
  "name": "Freedom Be With All 2023-06-10T11:46:34.966462Z",
  "lists": [
    3
  ],
  "headers": [
    {
      "Reply-To": "Antranig Vartanian <antranig@vartanian.am>"
    }
  ],
  "from_email": "Antranig Vartanian <newsletter@bsd.am>",
  "content_type": "markdown",
  "body": "# Freedom Be With All: 2023, W23\n## [5 Years of Blogging](https://weblog.antranigv.am/posts/2023/05/5-years-of-blogging/)\n5 years ago today, I wrote my first English blog post. At the time I was using Hugo, the hosting was (and still is) provided by me, with the electricity that comes to my house, with an ISP that gave me IP addresses for (kinda-)free and all of it using FreeBSD. These days, it’s not […]\n\n---\n## [Domains as Verification](https://weblog.antranigv.am/posts/2023/05/domains-as-verification/)\nCouple of days ago when I was browsing the internet I stumbled upon Jim Nielsen’s blog, where at the top it said Verified ($10/year for the domain) Luckily, his blog is so organized (unlike mine) where I found the post named Verified Personal Website in which he talked about this. Personally, I don’t have enough […]\n\n---\n## [Downtime for the rest of us](https://weblog.antranigv.am/posts/2023/05/downtime-for-the-rest-of-us/)\nIf the homebrew server club had an official membership based on technicality, then I would be a very proud member, but it does not have a membership application. That being said, I am still a proud member of HBSC, as I’ve been running a home server for a decade now. I can’t say that it’s […]\n"
}
```

---

I hope this tool would be useful for you, and if there are any features that you need, don't hesitate to open an issue.

Thank you!



