package com.example.demo.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.net.InetAddress;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class ApiController {

    private final long startTime = System.currentTimeMillis();

    @GetMapping
    public ResponseEntity<Map<String, Object>> getApiIndex() {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("message", "Welcome to Cloud Demo API v2.0");
        response.put("endpoints", Map.of(
            "dashboard", "/",
            "status", "/api/status",
            "health", "/api/health",
            "greet", "/api/greet?name={yourName}",
            "actuatorHealth", "/actuator/health"
        ));
        response.put("timestamp", Instant.now().toString());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> getHealth() {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("status", "UP");
        response.put("version", "2.0.0");
        response.put("timestamp", Instant.now().toString());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getStatus() {
        Map<String, Object> response = new LinkedHashMap<>();
        Runtime runtime = Runtime.getRuntime();

        long uptimeMillis = System.currentTimeMillis() - startTime;
        long uptimeSeconds = uptimeMillis / 1000;

        String hostname = "unknown";
        try {
            hostname = InetAddress.getLocalHost().getHostName();
        } catch (Exception ignored) {
        }

        response.put("application", "Cloud Demo Java App");
        response.put("version", "2.0.0");
        response.put("pipelineStatus", "Automated CI/CD via Jenkins");
        response.put("environment", "AWS EC2 Ubuntu (Build Agent)");
        response.put("hostname", hostname);
        response.put("os", System.getProperty("os.name") + " " + System.getProperty("os.version"));
        response.put("javaVersion", System.getProperty("java.version"));
        response.put("uptime", uptimeSeconds + "s");
        response.put("timestamp", Instant.now().toString());

        Map<String, Object> memory = new LinkedHashMap<>();
        long mb = 1024 * 1024;
        memory.put("usedMb", (runtime.totalMemory() - runtime.freeMemory()) / mb);
        memory.put("freeMb", runtime.freeMemory() / mb);
        memory.put("totalMb", runtime.totalMemory() / mb);
        memory.put("maxMb", runtime.maxMemory() / mb);
        response.put("jvmMemory", memory);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/greet")
    public ResponseEntity<Map<String, String>> greet(@RequestParam(defaultValue = "Shantanu") String name) {
        Map<String, String> response = new LinkedHashMap<>();
        response.put("message", "?? Hello " + name + "! Your CI/CD pipeline deployment to AWS EC2 was 100% successful.");
        response.put("version", "2.0.0");
        response.put("timestamp", Instant.now().toString());
        return ResponseEntity.ok(response);
    }
}
