#include <cstdio>
#include <vector>
#include <memory>
#include <node.h>
#include <v8.h>
#include <uv.h>

const char* ENTRY = R"(
const publicRequire = require('node:module').createRequire(process.cwd() + '/');
globalThis.require = publicRequire;
require('node:vm').runInThisContext(process.argv[1]);
)";

static int RunNodeInstance(
    node::MultiIsolatePlatform* platform,
    const std::vector<std::string>& args,
    const std::vector<std::string>& exec_args)
{
    int exit_code = 0;

    // Setup up a libuv event loop, v8::Isolate, and Node.js Environment.
    std::vector<std::string> errors;
    std::unique_ptr<node::CommonEnvironmentSetup> setup =
        node::CommonEnvironmentSetup::Create(platform, &errors, args, exec_args);
    if (!setup) {
        for (const std::string& err : errors) {
            std::fprintf(stderr, "%s: %s\n", args[0].c_str(), err.c_str());
        }
        return 1;
    }

    v8::Isolate* isolate = setup->isolate();
    node::Environment* env = setup->env();

    {
        v8::Locker locker(isolate);
        v8::Isolate::Scope isolate_scope(isolate);
        v8::HandleScope handle_scope(isolate);
        // The v8::Context needs to be entered when node::CreateEnvironment() and
        // node::LoadEnvironment() are being called.
        v8::Context::Scope context_scope(setup->context());

        // Set up the Node.js instance for execution, and run code inside of it.
        // There is also a variant that takes a callback and provides it with
        // the `require` and `process` objects, so that it can manually compile
        // and run scripts as needed.
        // The `require` function inside this script does *not* access the file
        // system, and can only load built-in Node.js modules.
        // `module.createRequire()` is being used to create one that is able to
        // load files from the disk, and uses the standard CommonJS file loader
        // instead of the internal-only `require` function.
        v8::MaybeLocal<v8::Value> loadenv_ret = node::LoadEnvironment(
            env,
            ENTRY);

        if (loadenv_ret.IsEmpty()) {  // There has been a JS exception.
            return 1;
        }

        exit_code = node::SpinEventLoop(env).FromMaybe(1);

        // node::Stop() can be used to explicitly stop the event loop and keep
        // further JavaScript from running. It can be called from any thread,
        // and will act like worker.terminate() if called from another thread.
        node::Stop(env);
    }

    return exit_code;
}

int main(int argc, char* argv[]) {
    argv = uv_setup_args(argc, argv);

    std::vector<std::string> args(argv, argv + argc);
    // Parse Node.js CLI options, and print any errors that have occurred while
    // trying to parse them.
    std::unique_ptr<node::InitializationResult> result =
        node::InitializeOncePerProcess(args, {
            node::ProcessInitializationFlags::kNoInitializeV8,
            node::ProcessInitializationFlags::kNoInitializeNodeV8Platform
        });

    for (const std::string& error : result->errors())
    std::fprintf(stderr, "%s: %s\n", args[0].c_str(), error.c_str());
    if (result->early_return() != 0) {
        return result->exit_code();
    }

    // Create a v8::Platform instance. `MultiIsolatePlatform::Create()` is a way
    // to create a v8::Platform instance that Node.js can use when creating
    // Worker threads. When no `MultiIsolatePlatform` instance is present,
    // Worker threads are disabled.
    std::unique_ptr<node::MultiIsolatePlatform> platform =
        node::MultiIsolatePlatform::Create(4);
    v8::V8::InitializePlatform(platform.get());
    v8::V8::Initialize();

    // See below for the contents of this function.
    int ret = RunNodeInstance(
        platform.get(), result->args(), result->exec_args());

    v8::V8::Dispose();
    v8::V8::DisposePlatform();

    node::TearDownOncePerProcess();
    return ret;
}
