package com.proconnect.proconnect.controller;

import com.proconnect.proconnect.service.aramaservice;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
public class aramacontroller {

    @Autowired
    private aramaservice aramaService;

    @PostMapping("/ara")
    public Map<String, Object> ara(@RequestBody Map<String, Object> body) throws Exception {
        String query = (String) body.get("query");
        Double lat = body.get("lat") != null ? ((Number) body.get("lat")).doubleValue() : null;
        Double lng = body.get("lng") != null ? ((Number) body.get("lng")).doubleValue() : null;
        String sehir = (String) body.get("sehir");

        return aramaService.ara(query, lat, lng, sehir);
    }
}
