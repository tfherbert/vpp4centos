#!/bin/bash
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
set -e

usage() {
    echo "$0 < -c -v -h?

    -h|?            -- print this message
    -w              -- -w no to disable clean up. Default is yes"
}

CLEAN=yes

while getopts "w:hv?" opt; do
    case "$opt" in
        w)
            CLEAN="${OPTARG}"
            ;;
        h|\?)
            usage
            exit 1
            ;;
    esac
done

echo =============================18.07================================
echo "Build vpp SRPM for 18.07 release"

./build-vpp-srpm.sh -g 18.07

if [[ -z "${CLEAN##*y*}" ]]; then
    ./clean.sh
fi

exit 0
