package com.example;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import spark.Request;
import spark.Response;
import static spark.Spark.*;

public class App {
    private static final Logger logger = LogManager.getLogger(App.class);

    public static void main(String[] args) {
        port(8080);

        staticFiles.location("/public");

        get("/log", (Request req, Response res) -> {
            String input = req.queryParams("input");
            if (input != null) {
                logger.info("User input: " + input);
                return "Logged: " + input;
            } else {
                return "Please provide input to log";
            }
        });

        get("/", (req, res) -> {
            res.redirect("/index.html");
            return null;
        });

        awaitInitialization();
        logger.info("Server is running on http://localhost:8080");
    }
}
