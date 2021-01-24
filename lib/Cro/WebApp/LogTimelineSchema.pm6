use Log::Timeline;

class Cro::WebApp::LogTimeline::CompileTemplate
        does Log::Timeline::Task['Cro', 'Template', 'Compile'] {}
class Cro::WebApp::LogTimeline::RenderTemplate
        does Log::Timeline::Task['Cro', 'Template', 'Render'] {}
