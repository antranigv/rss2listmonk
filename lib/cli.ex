defmodule Rss2listmonk.CLI do

  require IEx

  defp usage do
    IO.puts(
      """
      usage: ./rss2listmonk
        --feed https://awesome.blog/feed/
        --listmonk https://listmonk.app
        --user listmonk_user
        --password listmonk_pass
        --template id
        --lists 2,4,5
        [ --subject "Awesome blog ${date}" ]
        [ --from 'Awesome Blogger <newsletter@example.com>' ]
        [ --reply-to 'John Smithian <john@example.com>' ]
        [ --range 24H ]
        [ --lang en_US ]
      """
    )
    System.stop(1)
  end

  def main(args \\ []) do
    case parse_args(args) do
      {:ok, parsed} ->
        start(parsed)
      {:error} ->
        usage()
    end
  end

  defp start(parsed_args) do
    %{
      feed: feed,
      from: from,
      lang: lang,
      listmonk: listmonk,
      lists: lists,
      password: password,
      range: range,
      reply_to: reply_to,
      subject: subject,
      template: template_id,
      user: user,
    } = parsed_args

    range_int_h =
      range
      |> String.trim_trailing("H")
      |> String.to_integer

    range_int = range_int_h * 60 * 60

    {date, 0} =
      System.cmd(
        "date",
        ["+%A, %d %B, %Y"],
        env: [{"LANG", lang <> ".UTF-8"}]
      )

    parsed =
      feed
      |> fetch_data
      |> parse_xml

    title =
      parsed
      |> Quinn.find(:title)
      |> hd
      |> Map.get(:value)
      |> hd

    subject =
      subject
      |> String.replace("%title", title)
      |> String.replace("%date", date)

    message_body =
      parsed
      |> get_data
      |> filter_ranged(range_int)
      |> Enum.map(fn item -> item_to_markdown(item) end)
      |> Enum.join("\n---\n")

    case message_body do
      "" ->
        IO.puts("No items in the last #{range}")
      _ ->
        lists_array = lists |> String.split(",") |> Enum.map(fn int -> String.to_integer(int) end)

        campaign_headers = if reply_to, do: [%{"Reply-To" => reply_to}], else: []

        body = Poison.encode!(%{name: title <> " " <> (DateTime.utc_now |> DateTime.to_iso8601), subject: subject,
          lists: lists_array, from_email: from,
          content_type: "markdown", type: "regular", tags: ["blog"], send_later:
          false, send_at: nil, headers: campaign_headers,
          template_id: template_id,
          body: "# #{subject}\n" <> message_body
        })

        headers = [{"Content-type", "application/json"}]
        {:ok, resp} = HTTPoison.post(listmonk <> "/api/campaigns", body, headers, hackney: [basic_auth: {user, password}])

        id =
          resp
          |> Map.get(:body)
          |> Poison.decode!
          |> Map.get("data")
          |> Map.get("id")

        {:ok, _} =
          HTTPoison.put(
            listmonk <> "/api/campaigns/#{id}/status",
            Poison.encode!(%{status: "running"}),
            headers,
            hackney: [basic_auth: {user, password}]
          )
    end
  end

  defp parse_args(args) do
    {parsed, [], _rem} =
      OptionParser.parse(
        args,
        strict: [
          feed:     :string,
          from:     :string,
          lang:     :string,
          listmonk: :string,
          lists:    :string,
          password: :string,
          range:    :string,
          reply_to: :string,
          subject:  :string,
          template: :integer,
          user:     :string,
        ])

    parsed_keys = Keyword.keys(parsed)

    with true <-  :feed     in parsed_keys,
         true <-  :listmonk in parsed_keys,
         true <-  :lists    in parsed_keys,
         true <-  :password in parsed_keys,
         true <-  :template in parsed_keys,
         true <-  :user     in parsed_keys
    do
      :ok
      parsed = unless :reply_to in parsed_keys, do: Keyword.put(parsed, :reply_to,  nil),               else: parsed
      parsed = unless :from     in parsed_keys, do: Keyword.put(parsed, :from,      nil),               else: parsed
      parsed = unless :lang     in parsed_keys, do: Keyword.put(parsed, :lang,      "en_US"),           else: parsed
      parsed = unless :range    in parsed_keys, do: Keyword.put(parsed, :range,     "24H"),             else: parsed
      parsed = unless :subject  in parsed_keys, do: Keyword.put(parsed, :subject,   "%title: %date"),   else: parsed
      {:ok, Enum.into(parsed, %{})}
    else
      false ->
        {:error}
    end
  end

  defp fetch_data(url) do
    HTTPoison.get! url
  end

  defp parse_xml(resp) do
    Quinn.parse(resp.body)
  end

  defp get_data(data) do
    data
    |> Quinn.find(:item)
    |> Enum.map(fn item_map -> parse_item(item_map.value) end)
  end

  defp parse_item(data) do
    title = Quinn.find(data, :title) |> hd |> Map.get(:value) |> List.first

    date = Quinn.find(data, :pubDate) |> hd |> Map.get(:value) |> hd

    epoch =
      date
      |> DateTimeParser.parse_datetime!
      |> DateTime.to_unix

    description =
      data
      |> Quinn.find(:description)
      |> hd
      |> Map.get(:value)
      |> hd
      |> HtmlEntities.decode

    href =
      data
      |> Quinn.find(:link)
      |> hd
      |> Map.get(:value)
      |> hd

    %{title: title, date: date, epoch: epoch, description: description, href: href }
  end

  defp filter_ranged(items, range_int) do
    now = DateTime.utc_now |> DateTime.to_unix
    min_epoch = now - range_int

    filtered_items =
      Enum.filter(items,
        fn item ->
          item.epoch > min_epoch
        end
      )

    filtered_items
  end

  defp item_to_markdown(item) do
    title =
      case Map.get(item, :title) do
        nil -> "..."
        str -> str
      end
    """
    ## [#{title}](#{item.href})
    #{item.description}
    """
  end
end
