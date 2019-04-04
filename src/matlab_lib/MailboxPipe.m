classdef MailboxPipe
    properties
        recv_fn
        send_fn
    end
    methods
        function self = MailboxPipe(path)
            self.recv_fn = fullfile(path, '/cesm2mymodel.pipe');
            self.send_fn = fullfile(path, '/mymodel2cesm.pipe');
        end
 
        function msg = recv(self)
            fd = fopen(self.recv_fn, 'r');
            msg = self.parse(fscanf(fd, '%s'));
            fclose(fd);
        end 

        function send(self, msg)
            fd = fopen(self.send_fn, 'w');
            fwrite(fd, msg);
            fclose(fd);
        end

        function obj = parse(self, msg)
            obj = containers.Map
            pieces = split(msg, ';')
            for i = 1 : length(pieces)
                kvpair = split(pieces(i), ':')
                if length(kvpair) == 2
                    obj(char(kvpair(1))) = char(kvpair(2))
                end
            end
        end
    end
end
