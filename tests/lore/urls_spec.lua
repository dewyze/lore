local urls = require("lore.urls")

describe("lore.urls", function()
  describe("is_url", function()
    it("accepts http(s) urls", function()
      assert.is_true(urls.is_url("https://example.com/a?b=c"))
      assert.is_true(urls.is_url("http://x.io"))
    end)

    it("rejects everything else", function()
      assert.is_false(urls.is_url("just words"))
      assert.is_false(urls.is_url("ftp://old.school"))
      assert.is_false(urls.is_url("https://a.com plus trailing words"))
      assert.is_false(urls.is_url(""))
    end)
  end)

  describe("title_from_html", function()
    it("extracts and trims the title", function()
      assert.equals("My Page", urls.title_from_html("<html><title>\n  My Page\n</title></html>"))
    end)

    it("handles attributes and case", function()
      assert.equals("X", urls.title_from_html('<TITLE data-x="1">X</TITLE>'))
    end)

    it("decodes common entities and collapses whitespace", function()
      assert.equals(
        "Q&A: a < b",
        urls.title_from_html("<title>Q&amp;A:  a\n&lt; b</title>")
      )
    end)

    it("strips square brackets (they break the link)", function()
      assert.equals("draft 1", urls.title_from_html("<title>[draft] 1</title>"))
    end)

    it("is nil without a title", function()
      assert.is_nil(urls.title_from_html("<html><body>no title</body></html>"))
      assert.is_nil(urls.title_from_html("<title>   </title>"))
    end)
  end)

  describe("paste", function()
    it("falls through to normal paste for non-urls", function()
      vim.cmd.enew()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "start" })
      vim.fn.setreg('"', "plain text", "c")
      vim.api.nvim_win_set_cursor(0, { 1, 4 })
      urls.paste()
      -- feedkeys-based fallback needs the typeahead flushed
      vim.api.nvim_feedkeys("", "x", false)
      assert.equals("startplain text", vim.api.nvim_get_current_line())
    end)
  end)
end)
