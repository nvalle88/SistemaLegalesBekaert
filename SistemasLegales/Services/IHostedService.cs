﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace SistemasLegales.Services
{
    public interface IHostedService
    {
        Task EnviarNotificacionRequisitos();
    }
}
