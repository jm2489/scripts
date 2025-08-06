<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Core Keeper Server</title>
    <style>
        body {
            background-color: #1c1c1e;
            color: #f5f5f7;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 2rem;
            line-height: 1.6;
        }

        h1 {
            text-align: center;
            font-size: 3rem;
            margin-bottom: 1.5rem;
            color: #ffcc00;
            letter-spacing: 1px;
        }

        .container {
            max-width: 800px;
            margin: 1.5rem auto;
            background-color: #2c2c2e;
            padding: 2rem;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(255, 255, 255, 0.05);
        }
	.copy-container {
	    position: relative;
	    display: inline-block;
	    width: 100%;
	}

	.copy-container pre {
	    padding-right: 3rem;
	}

	.copy-btn {
	    position: absolute;
	    top: 0.5rem;
	    right: 0.5rem;
	    background: rgba(255, 255, 255, 0.1);
	    border: none;
	    color: #f5f5f7;
	    font-size: 1.2rem;
	    padding: 0.3rem 0.5rem;
	    border-radius: 5px;
	    cursor: pointer;
	    opacity: 0.3;
	    transition: opacity 0.2s ease, background 0.2s ease;
	}

	.copy-btn:hover {
	    opacity: 1;
	    background: rgba(255, 255, 255, 0.2);
	}

        pre {
            background-color: #3a3a3c;
            padding: 1rem;
            border-radius: 6px;
            overflow-x: auto;
            white-space: pre;
            font-size: 1rem;
            font-family: 'Courier New', Courier, monospace;
            color: #e6e6e6;
        }
	pre#game-id {
	    padding-right: 4rem;
        }
        .status-indicator {
            display: inline-block;
            padding: 0.3em 0.75em;
            font-size: 0.9rem;
            font-weight: bold;
            border-radius: 6px;
            margin-left: 0.5rem;
        }

        .status-green { background-color: #2ecc71; color: #fff; }
        .status-yellow { background-color: #f1c40f; color: #000; }
        .status-red { background-color: #e74c3c; color: #fff; }

        details summary {
            cursor: pointer;
            font-weight: bold;
            padding: 0.5rem 0;
        }

        details[open] summary::after {
            content: " ▲";
        }

        summary::after {
            content: " ▼";
        }
    </style>
</head>
<body>
    <h1>Core Keeper Server</h1>

    <div class="container">
        <h2>Game ID</h2>
        <?php
        $gameID = "/home/corekeeper-server/GameID.txt";
	$gameIdContent = file_exists($gameID) ? htmlspecialchars(trim(file_get_contents($gameID))) : "Game ID not available.";
	?>
	<pre id="game-id"><?= $gameIdContent ?></pre>
    </div>

    <div class="container">
        <h2>Server Update</h2>
        <?php
        $filename = "/var/www/html/update-status.txt";
        if (file_exists($filename)) {
            $statusText = trim(file_get_contents($filename));
            if (stripos($statusText, 'up to date') !== false) {
                echo '<span class="status-indicator status-green">Up to Date</span>';
            } else {
                echo '<span class="status-indicator status-yellow">Update Available</span>';
            }
        } else {
            echo '<span class="status-indicator status-red">Unavailable</span>';
            echo "<pre>No server information available. Please create a file named 'update-status.txt'.</pre>";
        }
        ?>
    </div>

    <div class="container">
        <h2>🛠️ Service Status</h2>
        <details>
            <summary>Show systemd service logs</summary>
            <?php
            $statusFile = "/var/www/html/service-status.txt";
            if (file_exists($statusFile)) {
                echo "<pre>" . htmlspecialchars(file_get_contents($statusFile)) . "</pre>";
            } else {
                echo "<pre>No service-status.txt found.</pre>";
            }
            ?>
        </details>
    </div>
</body>
</html>

