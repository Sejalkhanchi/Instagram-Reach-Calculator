<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*" %>
<!DOCTYPE html>
<html>
<head>
    <title>Instagram Reach Calculator</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background-color: #f0f0f0;
        }
        .container {
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            width: 100%;
            max-width: 600px;
        }
        h1 {
            color: #4CAF50;
            text-align: center;
        }
        form {
            margin-bottom: 20px;
        }
        label {
            display: inline-block;
            width: 150px;
        }
        input[type="number"], input[type="submit"] {
            padding: 10px;
            margin: 10px 0;
            width: calc(100% - 20px);
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        input[type="submit"] {
            background-color: #4CAF50;
            color: white;
            border: none;
            cursor: pointer;
        }
        input[type="submit"]:hover {
            background-color: #45a049;
        }
        .error {
            color: red;
            font-weight: bold;
            text-align: center;
        }
        .result {
            text-align: center;
            margin-top: 20px;
        }
        .chart-container {
            position: relative;
            height: 400px;
            width: 100%;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        function validateForm() {
            const followers = document.getElementById("followers").value;
            const reachRate = document.getElementById("reachRate").value;
            let errorMessage = "";

            if (followers <= 0) {
                errorMessage += "Number of followers must be greater than 0.\\n";
            }
            if (reachRate <= 0 || reachRate > 100) {
                errorMessage += "Reach rate must be between 1 and 100 percent.\\n";
            }
            
            if (errorMessage) {
                alert(errorMessage);
                return false;
            }
            return true;
        }

        function renderChart(reachRate) {
            const ctx = document.getElementById('reachChart').getContext('2d');
            new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: ['Reach', 'Remaining'],
                    datasets: [{
                        label: 'Reach Rate',
                        data: [reachRate, 100 - reachRate],
                        backgroundColor: ['#4CAF50', '#e0e0e0'],
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                }
            });
        }
    </script>
</head>
<body>
    <div class="container">
        <h1>Instagram Reach Calculator</h1>
        <form method="post" action="index.jsp" onsubmit="return validateForm()">
            <label for="followers">Number of Followers:</label>
            <input type="number" id="followers" name="followers" min="1" required>
            <br>
            <label for="reachRate">Reach Rate (%):</label>
            <input type="number" id="reachRate" name="reachRate" min="1" max="100" required>
            <br>
            <input type="submit" value="Calculate Reach">
        </form>

        <% 
            // Initialize error message
            String errorMessage = null;
            double reach = 0;
            double reachRate = 0;
            
            try {
                // Get parameters from the request
                String followersParam = request.getParameter("followers");
                String reachRateParam = request.getParameter("reachRate");
                
                if (followersParam != null && reachRateParam != null) {
                    // Convert parameters to integers
                    int followers = Integer.parseInt(followersParam);
                    reachRate = Double.parseDouble(reachRateParam);
                    
                    if (followers > 0 && reachRate > 0 && reachRate <= 100) {
                        // Calculate reach
                        reach = (followers * reachRate) / 100;

                        // Database connection parameters
                        String url = "jdbc:derby://localhost:1527/irc";
                        String user = "irc";
                        String password = "irc";
                        Connection conn = null;
                        PreparedStatement stmt = null;

                        try {
                            // Load JDBC driver
                            Class.forName("org.apache.derby.jdbc.ClientDriver");
                            
                            // Establish connection
                            conn = DriverManager.getConnection("jdbc:derby://localhost:1527/irc", "irc", "irc");
                            
                            // Prepare SQL query
                            String sql = "INSERT INTO instagram_reach (followers, reach_rate, calculated_reach) VALUES (?, ?, ?)";
                            stmt = conn.prepareStatement(sql);
                            stmt.setInt(1, followers);
                            stmt.setDouble(2, reachRate);
                            stmt.setDouble(3, reach);
                            
                            // Execute update
                            stmt.executeUpdate();
                            
                        } catch (Exception e) {
                            errorMessage = "Database connection failed: " + e.getMessage();
                        } finally {
                            if (stmt != null) stmt.close();
                            if (conn != null) conn.close();
                        }
                    } else {
                        errorMessage = "Invalid input values. Please ensure followers > 0 and reach rate between 1 and 100.";
                    }
                }
            } catch (NumberFormatException e) {
                errorMessage = "Please enter valid numbers.";
            } catch (SQLException e) {
                errorMessage = "SQL error: " + e.getMessage();
            }
        %>

        <% if (errorMessage != null) { %>
            <div class="error"><%= errorMessage %></div>
        <% } else if (reach > 0) { %>
            <div class="result">
                <h2>Calculated Reach: <%= reach %></h2>
                <div class="chart-container">
                    <canvas id="reachChart"></canvas>
                </div>
                <script>
                    renderChart(<%= reachRate %>);
                </script>
            </div>
        <% } %>
    </div>
</body>
</html>
