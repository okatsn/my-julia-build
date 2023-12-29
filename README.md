# KEYNOTE
1. The building of `my-julia-build` is controlled by `docker-compose.yml`.
2. Please follow the instruction in Dockerfile.
3. Those in `.devcontainer` is intended just for the convenience of building the image and open the container using VSCODE's interface. Without them, the building command instruction in Dockerfile should still work.
4. The `devcontainer.json` is suggested by VSCODE. 

# Next TODOs
- [ ] Find a way to synchronize all the `.env` files in different repos. For example, `okatsn/my-julia-build/.env` should describe the same environment variables as those in `okatsn/MyTeXLife/.devcontainer/.env`.