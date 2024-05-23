defmodule Autobuild.ParserTest do
  use ExUnit.Case

  test "it can flatten a list of imports correctly" do
    lines = [
      "import os\n",
      "import sys\n",
      "import time\n",
      "from poop import pee\n",
      "from datetime import (\n",
      "    datetime,\n",
      "    timedelta,\n",
      ")\n",
      "import time\n",
      "import time\n",
      "import time\n",
      "from foo import (bar, baz)\n",
      "from foo import (bar, baz)\n",
      "from foo import (bar, baz)\n",
      "import time\n",
      "import time\n",
    ]

    results = Autobuild.Parser.flatten(lines)

    assert results == [
             "from datetime import (datetime, timedelta)\n",
             "from foo import (bar, baz)\n",
             "from poop import pee\n",
             "import os\n",
             "import sys\n",
             "import time\n",
           ]
  end
end
