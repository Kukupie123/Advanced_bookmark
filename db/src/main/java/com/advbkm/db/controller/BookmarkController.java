package com.advbkm.db.controller;


import com.advbkm.db.models.entities.EntityBookmark;
import com.advbkm.db.models.exception.ResponseException;
import com.advbkm.db.models.reqresp.ReqResp;
import com.advbkm.db.service.BookmarkService;
import lombok.extern.log4j.Log4j2;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Log4j2
@RestController()
@RequestMapping("/api/v1/db/bookmark")
public class BookmarkController {
    private final BookmarkService bookmarkService;

    public BookmarkController(BookmarkService bookmarkService) {
        this.bookmarkService = bookmarkService;
    }

    @PostMapping("/create")
    public Mono<ResponseEntity<ReqResp<String>>> createBookmark(@RequestBody EntityBookmark bookmark, @RequestHeader("Authorization") String userID) {
        log.info("Create bookmark with body {}", bookmark);
        return bookmarkService.createBookmark(bookmark, userID)
                .map(
                        bkmID -> ResponseEntity.ok().body(new ReqResp<>(bkmID, "Success"))
                )
                .onErrorResume(
                        throwable -> Mono.just(ResponseEntity.status(((ResponseException) throwable).getStatusCode()).body(new ReqResp<>(null, throwable.getMessage())))
                )
                ;

    }

    @DeleteMapping("/{id}")
    public Mono<ResponseEntity<ReqResp<Boolean>>> deleteBookmark(@PathVariable String id, @RequestHeader("Authorization") String userID) {
        return bookmarkService.deleteBookmark(id, userID)
                .map(aBoolean -> ResponseEntity.ok(new ReqResp<>(aBoolean, "Success")))
                .onErrorResume(throwable -> {
                    var err = (ResponseException) throwable;
                    return Mono.just(
                            ResponseEntity.status(err.getStatusCode()).body(new ReqResp<>(null, err.getMessage()))
                    );
                });
    }

    @GetMapping("/{id}")
    public Mono<ResponseEntity<ReqResp<EntityBookmark>>> getBookmark(@PathVariable String id, @RequestHeader("Authorization") String userID) {
        return bookmarkService.getBookmark(id, userID)
                .map(bookmark -> ResponseEntity.ok(new ReqResp<>(bookmark, "")))
                .onErrorResume(e -> {
                    var err = (ResponseException) e;
                    return Mono.just(ResponseEntity.status(err.getStatusCode()).body(new ReqResp<>(null, err.getMessage())));
                })
                ;
    }

    @GetMapping("/dir/{dirID}")
    public Flux<ResponseEntity<ReqResp<EntityBookmark>>> getBookmarksFromDir(@PathVariable String dirID, @RequestHeader("Authorization") String userID) {
        return bookmarkService.getBookmarksFromDir(dirID, userID)
                .map(bookmark -> ResponseEntity.ok(new ReqResp<>(bookmark, "")))
                .onErrorResume(e -> Flux.just(
                        ResponseEntity.internalServerError().body(new ReqResp<>(null, e.getMessage()))
                ));
    }
}
